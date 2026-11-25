# Auto-generated client for Airflow API (Stable) v2.5.1
# Source: https://api.apis.guru/v2/specs/apache.org/airflow/2.5.1/openapi.json
# Auth: --token flag or $env.AIRFLOW_API_STABLE_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api/v1"
  token_env_var: "AIRFLOW_API_STABLE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: negotiate, in: header, header_name: Authorization, prefix: Negotiate}
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

def base-url-completer [] { ["https://api.apis.guru/api/v1" "https://apache.local"] }
def auth-scheme-completer [] { ["basic" "bearer" "negotiate" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }
def accept-completer-1 [] { ["application/json" "plain/text"] }
def state-completer [] { ["failed" "queued" "running" "success"] }
def state-completer-1 [] { ["failed" "queued" "success"] }
def new-state-completer [] { ["failed" "success"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-config: "record<sections: table<name: string, options: list>>"
    get-connections: "record<connections: table<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string>, total_entries: int>"
    post-connection: "record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>"
    test-connection: "record<message: string, status: bool>"
    get-connection: "record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>"
    patch-connection: "record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>"
    get-dag-source: "record<content: string>"
    get-dag-warnings: "record<import_errors: table<dag_id: string, message: string, timestamp: string, warning_type: string>, total_entries: int>"
    get-dags: "record<dags: table<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list, timetable_description: string>, total_entries: int>"
    patch-dags: "record<dags: table<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list, timetable_description: string>, total_entries: int>"
    get-dag: "record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string>"
    patch-dag: "record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string>"
    post-clear-task-instances: "record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>>"
    get-dag-runs: "record<dag_runs: table<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>, total_entries: int>"
    post-dag-run: "record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>"
    get-dag-run: "record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>"
    update-dag-run-state: "record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>"
    clear-dag-run: "record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>"
    set-dag-run-note: "record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>"
    get-task-instances: "record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>"
    get-task-instance: "record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>"
    patch-task-instance: "record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>"
    get-extra-links: "record<extra_links: table<class_ref: record, href: string, name: string>>"
    get-mapped-task-instances: "record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>"
    get-log: "record<content: string, continuation_token: string>"
    set-task-instance-note: "record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>"
    get-xcom-entries: "record<xcom_entries: table<dag_id: string, execution_date: string, key: string, task_id: string, timestamp: string>, total_entries: int>"
    get-xcom-entry: "record<dag_id: string, execution_date: string, key: string, task_id: string, timestamp: string, value: string>"
    get-mapped-task-instance: "record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>"
    patch-mapped-task-instance: "record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>"
    set-mapped-task-instance-note: "record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>"
    get-upstream-dataset-events: "record<dataset_events: table<created_dagruns: list, dataset_id: int, dataset_uri: string, extra: record, source_dag_id: string, source_map_index: int, source_run_id: string, source_task_id: string, timestamp: string>, total_entries: int>"
    get-dag-details: "record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string, catchup: bool, concurrency: float, dag_run_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, doc_md: string, end_date: string, is_paused_upon_creation: bool, last_parsed: string, orientation: string, params: record, render_template_as_native_obj: bool, start_date: string, template_search_path: list<string>, timezone: string>"
    get-tasks: "record<tasks: table<class_ref: record, depends_on_past: bool, downstream_task_ids: list, end_date: string, execution_timeout: record, extra_links: list, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record, retry_exponential_backoff: bool, start_date: string, sub_dag: record, task_id: string, template_fields: list, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string>>"
    get-task: "record<class_ref: record<class_name: string, module_path: string>, depends_on_past: bool, downstream_task_ids: list<string>, end_date: string, execution_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, extra_links: table<class_ref: record>, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record<__type: string, days: int, microseconds: int, seconds: int>, retry_exponential_backoff: bool, start_date: string, sub_dag: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list<record>, timetable_description: string>, task_id: string, template_fields: list<string>, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string>"
    post-set-task-instances-state: "record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>>"
    get-dag-runs-batch: "record<dag_runs: table<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>, total_entries: int>"
    get-task-instances-batch: "record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>"
    get-datasets: "record<datasets: table<consuming_dags: list, created_at: string, extra: record, id: int, producing_tasks: list, updated_at: string, uri: string>, total_entries: int>"
    get-dataset-events: "record<dataset_events: table<created_dagruns: list, dataset_id: int, dataset_uri: string, extra: record, source_dag_id: string, source_map_index: int, source_run_id: string, source_task_id: string, timestamp: string>, total_entries: int>"
    get-dataset: "record<consuming_dags: table<created_at: string, dag_id: string, updated_at: string>, created_at: string, extra: record, id: int, producing_tasks: table<created_at: string, dag_id: string, task_id: string, updated_at: string>, updated_at: string, uri: string>"
    get-event-logs: "record<event_logs: table<dag_id: string, event: string, event_log_id: int, execution_date: string, extra: string, owner: string, task_id: string, when: string>, total_entries: int>"
    get-event-log: "record<dag_id: string, event: string, event_log_id: int, execution_date: string, extra: string, owner: string, task_id: string, when: string>"
    get-health: "record<metadatabase: record<status: string>, scheduler: record<latest_scheduler_heartbeat: string, status: string>>"
    get-import-errors: "record<import_errors: table<filename: string, import_error_id: int, stack_trace: string, timestamp: string>, total_entries: int>"
    get-import-error: "record<filename: string, import_error_id: int, stack_trace: string, timestamp: string>"
    get-permissions: "record<actions: table<name: string>, total_entries: int>"
    get-plugins: "record<plugins: table<appbuilder_menu_items: list, appbuilder_views: list, executors: list, flask_blueprints: list, global_operator_extra_links: list, hooks: list, macros: list, name: string, operator_extra_links: list, source: string>, total_entries: int>"
    get-pools: "record<pools: table<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>, total_entries: int>"
    post-pool: "record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>"
    get-pool: "record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>"
    patch-pool: "record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>"
    get-providers: "record<providers: table<description: string, package_name: string, version: string>, total_entries: int>"
    get-roles: "record<roles: table<actions: list, name: string>, total_entries: int>"
    post-role: "record<actions: table<action: record, resource: record>, name: string>"
    get-role: "record<actions: table<action: record, resource: record>, name: string>"
    patch-role: "record<actions: table<action: record, resource: record>, name: string>"
    get-users: "record<users: table<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: list, username: string>, total_entries: int>"
    post-user: "record<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: table<name: string>, username: string, password: string>"
    get-user: "record<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: table<name: string>, username: string>"
    patch-user: "record<actions: table<action: record, resource: record>, name: string>"
    get-variables: "record<variables: table<description: string, key: string>, total_entries: int>"
    post-variables: "record<description: string, key: string, value: string>"
    get-variable: "record<description: string, key: string, value: string>"
    patch-variable: "record<description: string, key: string, value: string>"
    get-version: "record<git_version: string, version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-config" "get-connections" "post-connection" "test-connection" "delete-connection" "get-connection" "patch-connection" "get-dag-source" "get-dag-warnings" "get-dags" "patch-dags" "delete-dag" "get-dag" "patch-dag" "post-clear-task-instances" "get-dag-runs" "post-dag-run" "delete-dag-run" "get-dag-run" "update-dag-run-state" "clear-dag-run" "set-dag-run-note" "get-task-instances" "get-task-instance" "patch-task-instance" "get-extra-links" "get-mapped-task-instances" "get-log" "set-task-instance-note" "get-xcom-entries" "get-xcom-entry" "get-mapped-task-instance" "patch-mapped-task-instance" "set-mapped-task-instance-note" "get-upstream-dataset-events" "get-dag-details" "get-tasks" "get-task" "post-set-task-instances-state" "get-dag-runs-batch" "get-task-instances-batch" "get-datasets" "get-dataset-events" "get-dataset" "get-event-logs" "get-event-log" "get-health" "get-import-errors" "get-import-error" "get-permissions" "get-plugins" "get-pools" "post-pool" "delete-pool" "get-pool" "patch-pool" "get-providers" "get-roles" "post-role" "delete-role" "get-role" "patch-role" "get-users" "post-user" "delete-user" "get-user" "patch-user" "get-variables" "post-variables" "delete-variable" "get-variable" "patch-variable" "get-version" "commands"] | sort) } | get name | first)
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

# Get current configuration
#
# GET /config
# Returns: record<sections: table<name: string, options: list>>
# operationId: get_config
export def "get-config" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/config"
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List connections
#
# GET /connections
# Returns: record<connections: table<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string>, total_entries: int>
# operationId: get_connections
export def "get-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a connection
#
# POST /connections
# Returns: record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>
# operationId: post_connection
export def "post-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conn-type: string # The connection type.
  --connection-id: string # The connection ID.
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connections"
    body: {content_type: "application/json", kind: json, fields: [{name: conn_type, var: conn_type}, {name: connection_id, var: connection_id}, {name: description, var: description}, {name: host, var: host}, {name: login, var: login}, {name: port, var: port}, {name: schema, var: schema}, {name: extra, var: extra}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    conn_type: $conn_type, connection_id: $connection_id, description: $description, host: $host, login: $login, port: $port, schema: $schema, extra: $extra, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test a connection
#
# POST /connections/test
# Returns: record<message: string, status: bool>
# operationId: test_connection
export def "test-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conn-type: string # The connection type.
  --connection-id: string # The connection ID.
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connections/test"
    body: {content_type: "application/json", kind: json, fields: [{name: conn_type, var: conn_type}, {name: connection_id, var: connection_id}, {name: description, var: description}, {name: host, var: host}, {name: login, var: login}, {name: port, var: port}, {name: schema, var: schema}, {name: extra, var: extra}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    conn_type: $conn_type, connection_id: $connection_id, description: $description, host: $host, login: $login, port: $port, schema: $schema, extra: $extra, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a connection
#
# DELETE /connections/{connection_id}
# operationId: delete_connection
export def "delete-connection" [
  connection_id: string
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
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connection
#
# GET /connections/{connection_id}
# Returns: record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>
# operationId: get_connection
export def "get-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    connection_id: $connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connection
#
# PATCH /connections/{connection_id}
# Returns: record<conn_type: string, connection_id: string, description: string, host: string, login: string, port: int, schema: string, extra: string, password: string>
# operationId: patch_connection
export def "patch-connection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --conn-type: string # The connection type.
  --body-connection-id: string # The connection ID. (spec name: connection_id)
  --description: string # The description of the connection. (nullable)
  --host: string # Host of the connection. (nullable)
  --login: string # Login of the connection. (nullable)
  --port: int # Port of the connection. (nullable)
  --schema: string # Schema of the connection. (nullable)
  --extra: string # Other values that cannot be put into another field, e.g. RSA keys. (nullable)
  --password: string # Password of the connection. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/connections/{connection_id}"
    path_params: [{name: connection_id, var: connection_id}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: conn_type, var: conn_type}, {name: connection_id, var: body_connection_id}, {name: description, var: description}, {name: host, var: host}, {name: login, var: login}, {name: port, var: port}, {name: schema, var: schema}, {name: extra, var: extra}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    connection_id: $connection_id, update_mask: $update_mask, conn_type: $conn_type, body_connection_id: $body_connection_id, description: $description, host: $host, login: $login, port: $port, schema: $schema, extra: $extra, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a source code
#
# GET /dagSources/{file_token}
# Returns: record<content: string>
# operationId: get_dag_source
export def "get-dag-source" [
  file_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dagSources/{file_token}"
    path_params: [{name: file_token, var: file_token}]
    accept: ["application/json", "plain/text"]
    ok: [200]
    auth: basic
  } {
    file_token: $file_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List dag warnings
#
# GET /dagWarnings
# Returns: record<import_errors: table<dag_id: string, message: string, timestamp: string, warning_type: string>, total_entries: int>
# operationId: get_dag_warnings
export def "get-dag-warnings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-id: string # If set, only return DAG warnings with this dag_id.
  --warning-type: string # If set, only return DAG warnings with this type.
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dagWarnings"
    query: [{name: dag_id, var: dag_id}, {name: warning_type, var: warning_type}, {name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, warning_type: $warning_type, limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List DAGs
#
# GET /dags
# Returns: record<dags: table<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list, timetable_description: string>, total_entries: int>
# operationId: get_dags
export def "get-dags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --tags: list<string> # List of tags to filter results. *New in version 2.2.0*
  --only-active: oneof<nothing, bool> # Only filter active DAGs. *New in version 2.1.1* (default: true)
  --dag-id-pattern: string # If set, only return DAGs with dag_ids matching this pattern.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}, {name: tags, var: tags, style: multi}, {name: only_active, var: only_active}, {name: dag_id_pattern, var: dag_id_pattern}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by, tags: $tags, only_active: $only_active, dag_id_pattern: $dag_id_pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update DAGs
#
# PATCH /dags
# Returns: record<dags: table<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list, timetable_description: string>, total_entries: int>
# operationId: patch_dags
export def "patch-dags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --tags: list<string> # List of tags to filter results. *New in version 2.2.0*
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --only-active: oneof<nothing, bool> # Only filter active DAGs. *New in version 2.1.1* (default: true)
  --dag-id-pattern: string # If set, only update DAGs with dag_ids matching this pattern. (required)
  --is-paused: oneof<nothing, bool> # Whether the DAG is paused. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: tags, var: tags, style: multi}, {name: update_mask, var: update_mask, style: csv}, {name: only_active, var: only_active}, {name: dag_id_pattern, var: dag_id_pattern, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_paused, var: is_paused}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, tags: $tags, update_mask: $update_mask, only_active: $only_active, dag_id_pattern: $dag_id_pattern, is_paused: $is_paused
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a DAG
#
# DELETE /dags/{dag_id}
# operationId: delete_dag
export def "delete-dag" [
  dag_id: string
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
    path: "/dags/{dag_id}"
    path_params: [{name: dag_id, var: dag_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dag_id: $dag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get basic information about a DAG
#
# GET /dags/{dag_id}
# Returns: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string>
# operationId: get_dag
export def "get-dag" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}"
    path_params: [{name: dag_id, var: dag_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a DAG
#
# PATCH /dags/{dag_id}
# Returns: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string>
# operationId: patch_dag
export def "patch-dag" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --is-paused: oneof<nothing, bool> # Whether the DAG is paused. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}"
    path_params: [{name: dag_id, var: dag_id}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_paused, var: is_paused}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, update_mask: $update_mask, is_paused: $is_paused
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear a set of task instances
#
# POST /dags/{dag_id}/clearTaskInstances
# Returns: record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>>
# operationId: post_clear_task_instances
export def "post-clear-task-instances" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-run-id: string # The DagRun ID for this task instance (nullable)
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be cleaned, but not modified in any way. (default: true) (spec name: dry_run)
  --end-date: string # The maximum execution date to clear. (format: datetime)
  --include-downstream: oneof<nothing, bool> # If set to true, downstream tasks are also affected. (default: false)
  --include-future: oneof<nothing, bool> # If set to True, also tasks from future DAG Runs are affected. (default: false)
  --include-parentdag: oneof<nothing, bool> # Clear tasks in the parent dag of the subdag.
  --include-past: oneof<nothing, bool> # If set to True, also tasks from past DAG Runs are affected. (default: false)
  --include-subdags: oneof<nothing, bool> # Clear tasks in subdags and clear external tasks indicated by ExternalTaskMarker.
  --include-upstream: oneof<nothing, bool> # If set to true, upstream tasks are also affected. (default: false)
  --only-failed: oneof<nothing, bool> # Only clear failed tasks. (default: true)
  --only-running: oneof<nothing, bool> # Only clear running tasks. (default: false)
  --reset-dag-runs: oneof<nothing, bool> # Set state of DAG runs to RUNNING.
  --start-date: string # The minimum execution date to clear. (format: datetime)
  --task-ids: list<string> # A list of task ids to clear. *New in version 2.1.0*
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/{dag_id}/clearTaskInstances"
    path_params: [{name: dag_id, var: dag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dag_run_id, var: dag_run_id}, {name: dry_run, var: body_dry_run}, {name: end_date, var: end_date}, {name: include_downstream, var: include_downstream}, {name: include_future, var: include_future}, {name: include_parentdag, var: include_parentdag}, {name: include_past, var: include_past}, {name: include_subdags, var: include_subdags}, {name: include_upstream, var: include_upstream}, {name: only_failed, var: only_failed}, {name: only_running, var: only_running}, {name: reset_dag_runs, var: reset_dag_runs}, {name: start_date, var: start_date}, {name: task_ids, var: task_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, body_dry_run: $body_dry_run, end_date: $end_date, include_downstream: $include_downstream, include_future: $include_future, include_parentdag: $include_parentdag, include_past: $include_past, include_subdags: $include_subdags, include_upstream: $include_upstream, only_failed: $only_failed, only_running: $only_running, reset_dag_runs: $reset_dag_runs, start_date: $start_date, task_ids: $task_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List DAG runs
#
# GET /dags/{dag_id}/dagRuns
# Returns: record<dag_runs: table<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>, total_entries: int>
# operationId: get_dag_runs
export def "get-dag-runs" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns"
    path_params: [{name: dag_id, var: dag_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: execution_date_gte, var: execution_date_gte}, {name: execution_date_lte, var: execution_date_lte}, {name: start_date_gte, var: start_date_gte}, {name: start_date_lte, var: start_date_lte}, {name: end_date_gte, var: end_date_gte}, {name: end_date_lte, var: end_date_lte}, {name: state, var: state, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, limit: $limit, offset: $offset, execution_date_gte: $execution_date_gte, execution_date_lte: $execution_date_lte, start_date_gte: $start_date_gte, start_date_lte: $start_date_lte, end_date_gte: $end_date_gte, end_date_lte: $end_date_lte, state: $state, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a new DAG run
#
# POST /dags/{dag_id}/dagRuns
# Returns: record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>
# operationId: post_dag_run
@deprecated --flag execution-date
export def "post-dag-run" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conf: record # JSON object describing additional configuration parameters. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error.
  --dag-run-id: string # Run ID. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error. If not provided, a value will be generated based on execution_date. If the specified dag_run_id is in use, the creation request fails with an ALREADY_EXISTS error. This together with DAG_ID are a unique key. (nullable)
  --execution-date: string # The execution date. This is the same as logical_date, kept for backwards compatibility. If both this field and logical_date are provided but with different values, the request will fail with an BAD_REQUEST error. *Changed in version 2.2.0*&#58; Field becomes nullable. *Deprecated since version 2.2.0*&#58; Use 'logical_date' instead. (DEPRECATED, nullable, format: date-time)
  --logical-date: string # The logical date (previously called execution date). This is the time or interval covered by this DAG run, according to the DAG definition. The value of this field can be set only when creating the object. If you try to modify the field of an existing object, the request fails with an BAD_REQUEST error. This together with DAG_ID are a unique key. *New in version 2.2.0* (nullable, format: date-time)
  --note: string # Contains manually entered notes by the user about the DagRun. *New in version 2.5.0* (nullable)
  --state: string@state-completer # DAG State. *Changed in version 2.1.3*&#58; 'queued' is added as a possible value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/{dag_id}/dagRuns"
    path_params: [{name: dag_id, var: dag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conf, var: conf}, {name: dag_run_id, var: dag_run_id}, {name: execution_date, var: execution_date}, {name: logical_date, var: logical_date}, {name: note, var: note}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, conf: $conf, dag_run_id: $dag_run_id, execution_date: $execution_date, logical_date: $logical_date, note: $note, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a DAG run
#
# DELETE /dags/{dag_id}/dagRuns/{dag_run_id}
# operationId: delete_dag_run
export def "delete-dag-run" [
  dag_id: string
  dag_run_id: string
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a DAG run
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}
# Returns: record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>
# operationId: get_dag_run
export def "get-dag-run" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a DAG run
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}
# Returns: record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>
# operationId: update_dag_run_state
export def "update-dag-run-state" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The state to set this DagRun
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear a DAG run
#
# POST /dags/{dag_id}/dagRuns/{dag_run_id}/clear
# Returns: record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>
# operationId: clear_dag_run
export def "clear-dag-run" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be cleaned, but not modified in any way. (default: true) (spec name: dry_run)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/clear"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dry_run, var: body_dry_run}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, body_dry_run: $body_dry_run
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the DagRun note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/setNote
# Returns: record<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>
# operationId: set_dag_run_note
export def "set-dag-run-note" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string # Custom notes left by users for this Dag Run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/setNote"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List task instances
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances
# Returns: record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>
# operationId: get_task_instances
export def "get-task-instances" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --duration-gte: float # Returns objects greater than or equal to the specified values. This can be combined with duration_lte parameter to receive only the selected period.
  --duration-lte: float # Returns objects less than or equal to the specified values. This can be combined with duration_gte parameter to receive only the selected range.
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --pool: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --queue: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    query: [{name: execution_date_gte, var: execution_date_gte}, {name: execution_date_lte, var: execution_date_lte}, {name: start_date_gte, var: start_date_gte}, {name: start_date_lte, var: start_date_lte}, {name: end_date_gte, var: end_date_gte}, {name: end_date_lte, var: end_date_lte}, {name: duration_gte, var: duration_gte}, {name: duration_lte, var: duration_lte}, {name: state, var: state, style: multi}, {name: pool, var: pool, style: multi}, {name: queue, var: queue, style: multi}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, execution_date_gte: $execution_date_gte, execution_date_lte: $execution_date_lte, start_date_gte: $start_date_gte, start_date_lte: $start_date_lte, end_date_gte: $end_date_gte, end_date_lte: $end_date_lte, duration_gte: $duration_gte, duration_lte: $duration_lte, state: $state, pool: $pool, queue: $queue, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a task instance
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}
# Returns: record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>
# operationId: get_task_instance
export def "get-task-instance" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of a task instance
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}
# Returns: record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>
# operationId: patch_task_instance
export def "patch-task-instance" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain the task instance planned to be affected, but won't be modified in any way. (default: false) (spec name: dry_run)
  --new-state: string@new-state-completer # Expected new state.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dry_run, var: body_dry_run}, {name: new_state, var: new_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, body_dry_run: $body_dry_run, new_state: $new_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List extra links
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/links
# Returns: record<extra_links: table<class_ref: record, href: string, name: string>>
# operationId: get_extra_links
export def "get-extra-links" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/links"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List mapped task instances
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/listMapped
# Returns: record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>
# operationId: get_mapped_task_instances
export def "get-mapped-task-instances" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --duration-gte: float # Returns objects greater than or equal to the specified values. This can be combined with duration_lte parameter to receive only the selected period.
  --duration-lte: float # Returns objects less than or equal to the specified values. This can be combined with duration_gte parameter to receive only the selected range.
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --pool: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --queue: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/listMapped"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: execution_date_gte, var: execution_date_gte}, {name: execution_date_lte, var: execution_date_lte}, {name: start_date_gte, var: start_date_gte}, {name: start_date_lte, var: start_date_lte}, {name: end_date_gte, var: end_date_gte}, {name: end_date_lte, var: end_date_lte}, {name: duration_gte, var: duration_gte}, {name: duration_lte, var: duration_lte}, {name: state, var: state, style: multi}, {name: pool, var: pool, style: multi}, {name: queue, var: queue, style: multi}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, limit: $limit, offset: $offset, execution_date_gte: $execution_date_gte, execution_date_lte: $execution_date_lte, start_date_gte: $start_date_gte, start_date_lte: $start_date_lte, end_date_gte: $end_date_gte, end_date_lte: $end_date_lte, duration_gte: $duration_gte, duration_lte: $duration_lte, state: $state, pool: $pool, queue: $queue, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get logs
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/logs/{task_try_number}
# Returns: record<content: string, continuation_token: string>
# operationId: get_log
export def "get-log" [
  dag_id: string
  dag_run_id: string
  task_id: string
  task_try_number: int
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
  --full-content: oneof<nothing, bool> # A full content will be returned. By default, only the first fragment will be returned.
  --map-index: int # Filter on map index for mapped task.
  --qp-token: string # A token that allows you to continue fetching logs. If passed, it will specify the location from which the download should be continued. (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/logs/{task_try_number}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}, {name: task_try_number, var: task_try_number}]
    query: [{name: full_content, var: full_content}, {name: map_index, var: map_index}, {name: token, var: qp_token}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, task_try_number: $task_try_number, full_content: $full_content, map_index: $map_index, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the TaskInstance note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/setNote
# Returns: record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>
# operationId: set_task_instance_note
export def "set-task-instance-note" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The custom note to set for this Task Instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/setNote"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List XCom entries
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries
# Returns: record<xcom_entries: table<dag_id: string, execution_date: string, key: string, task_id: string, timestamp: string>, total_entries: int>
# operationId: get_xcom_entries
export def "get-xcom-entries" [
  dag_id: string
  dag_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an XCom entry
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries/{xcom_key}
# Returns: record<dag_id: string, execution_date: string, key: string, task_id: string, timestamp: string, value: string>
# operationId: get_xcom_entry
export def "get-xcom-entry" [
  dag_id: string
  dag_run_id: string
  task_id: string
  xcom_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deserialize: oneof<nothing, bool> # Whether to deserialize an XCom value when using a custom XCom backend. The XCom API endpoint calls `orm_deserialize_value` by default since an XCom may contain value that is potentially expensive to deserialize in the web server. Setting this to true overrides the consideration, and calls `deserialize_value` instead. This parameter is not meaningful when using the default XCom backend. *New in version 2.4.0* (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/xcomEntries/{xcom_key}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}, {name: xcom_key, var: xcom_key}]
    query: [{name: deserialize, var: deserialize}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, xcom_key: $xcom_key, deserialize: $deserialize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a mapped task instance
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}
# Returns: record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>
# operationId: get_mapped_task_instance
export def "get-mapped-task-instance" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}, {name: map_index, var: map_index}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, map_index: $map_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state of a mapped task instance
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}
# Returns: record<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>
# operationId: patch_mapped_task_instance
export def "patch-mapped-task-instance" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain the task instance planned to be affected, but won't be modified in any way. (default: false) (spec name: dry_run)
  --new-state: string@new-state-completer # Expected new state.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}, {name: map_index, var: map_index}]
    body: {content_type: "application/json", kind: json, fields: [{name: dry_run, var: body_dry_run}, {name: new_state, var: new_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, map_index: $map_index, body_dry_run: $body_dry_run, new_state: $new_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the TaskInstance note.
#
# PATCH /dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}/setNote
# Returns: record<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record<dag_id: string, description: string, email_sent: bool, execution_date: string, notification_sent: bool, task_id: string, timestamp: string>, start_date: string, state: string, task_id: string, trigger: record<classpath: string, created_date: string, id: int, kwargs: string, triggerer_id: int>, triggerer_job: record<dag_id: string, end_date: string, executor_class: string, hostname: string, id: int, job_type: string, latest_heartbeat: string, start_date: string, state: string, unixname: string>, try_number: int, unixname: string>
# operationId: set_mapped_task_instance_note
export def "set-mapped-task-instance-note" [
  dag_id: string
  dag_run_id: string
  task_id: string
  map_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The custom note to set for this Task Instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances/{task_id}/{map_index}/setNote"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}, {name: task_id, var: task_id}, {name: map_index, var: map_index}]
    body: {content_type: "application/json", kind: json, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, task_id: $task_id, map_index: $map_index, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dataset events for a DAG run
#
# GET /dags/{dag_id}/dagRuns/{dag_run_id}/upstreamDatasetEvents
# Returns: record<dataset_events: table<created_dagruns: list, dataset_id: int, dataset_uri: string, extra: record, source_dag_id: string, source_map_index: int, source_run_id: string, source_task_id: string, timestamp: string>, total_entries: int>
# operationId: get_upstream_dataset_events
export def "get-upstream-dataset-events" [
  dag_id: string
  dag_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/dagRuns/{dag_run_id}/upstreamDatasetEvents"
    path_params: [{name: dag_id, var: dag_id}, {name: dag_run_id, var: dag_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a simplified representation of DAG
#
# GET /dags/{dag_id}/details
# Returns: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: table<name: string>, timetable_description: string, catchup: bool, concurrency: float, dag_run_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, doc_md: string, end_date: string, is_paused_upon_creation: bool, last_parsed: string, orientation: string, params: record, render_template_as_native_obj: bool, start_date: string, template_search_path: list<string>, timezone: string>
# operationId: get_dag_details
export def "get-dag-details" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/details"
    path_params: [{name: dag_id, var: dag_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks for DAG
#
# GET /dags/{dag_id}/tasks
# Returns: record<tasks: table<class_ref: record, depends_on_past: bool, downstream_task_ids: list, end_date: string, execution_timeout: record, extra_links: list, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record, retry_exponential_backoff: bool, start_date: string, sub_dag: record, task_id: string, template_fields: list, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string>>
# operationId: get_tasks
export def "get-tasks" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dags/{dag_id}/tasks"
    path_params: [{name: dag_id, var: dag_id}]
    query: [{name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get simplified representation of a task
#
# GET /dags/{dag_id}/tasks/{task_id}
# Returns: record<class_ref: record<class_name: string, module_path: string>, depends_on_past: bool, downstream_task_ids: list<string>, end_date: string, execution_timeout: record<__type: string, days: int, microseconds: int, seconds: int>, extra_links: table<class_ref: record>, is_mapped: bool, owner: string, pool: string, pool_slots: float, priority_weight: float, queue: string, retries: float, retry_delay: record<__type: string, days: int, microseconds: int, seconds: int>, retry_exponential_backoff: bool, start_date: string, sub_dag: record<dag_id: string, default_view: string, description: string, file_token: string, fileloc: string, has_import_errors: bool, has_task_concurrency_limits: bool, is_active: bool, is_paused: bool, is_subdag: bool, last_expired: string, last_parsed_time: string, last_pickled: string, max_active_runs: int, max_active_tasks: int, next_dagrun: string, next_dagrun_create_after: string, next_dagrun_data_interval_end: string, next_dagrun_data_interval_start: string, owners: list<string>, pickle_id: string, root_dag_id: string, schedule_interval: any, scheduler_lock: bool, tags: list<record>, timetable_description: string>, task_id: string, template_fields: list<string>, trigger_rule: string, ui_color: string, ui_fgcolor: string, wait_for_downstream: bool, weight_rule: string>
# operationId: get_task
export def "get-task" [
  dag_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/dags/{dag_id}/tasks/{task_id}"
    path_params: [{name: dag_id, var: dag_id}, {name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a state of task instances
#
# POST /dags/{dag_id}/updateTaskInstancesState
# Returns: record<task_instances: table<dag_id: string, dag_run_id: string, execution_date: string, task_id: string>>
# operationId: post_set_task_instances_state
export def "post-set-task-instances-state" [
  dag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-run-id: string # The task instance's DAG run ID. Either set this or execution_date but not both. *New in version 2.3.0*
  --body-dry-run: oneof<nothing, bool> # If set, don't actually run this operation. The response will contain a list of task instances planned to be affected, but won't be modified in any way. (default: true) (spec name: dry_run)
  --execution-date: string # The execution date. Either set this or dag_run_id but not both. (format: datetime)
  --include-downstream: oneof<nothing, bool> # If set to true, downstream tasks are also affected.
  --include-future: oneof<nothing, bool> # If set to True, also tasks from future DAG Runs are affected.
  --include-past: oneof<nothing, bool> # If set to True, also tasks from past DAG Runs are affected.
  --include-upstream: oneof<nothing, bool> # If set to true, upstream tasks are also affected.
  --new-state: string@new-state-completer # Expected new state.
  --task-id: string # The task ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/{dag_id}/updateTaskInstancesState"
    path_params: [{name: dag_id, var: dag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dag_run_id, var: dag_run_id}, {name: dry_run, var: body_dry_run}, {name: execution_date, var: execution_date}, {name: include_downstream, var: include_downstream}, {name: include_future, var: include_future}, {name: include_past, var: include_past}, {name: include_upstream, var: include_upstream}, {name: new_state, var: new_state}, {name: task_id, var: task_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_id: $dag_id, dag_run_id: $dag_run_id, body_dry_run: $body_dry_run, execution_date: $execution_date, include_downstream: $include_downstream, include_future: $include_future, include_past: $include_past, include_upstream: $include_upstream, new_state: $new_state, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List DAG runs (batch)
#
# POST /dags/~/dagRuns/list
# Returns: record<dag_runs: table<conf: record, dag_id: string, dag_run_id: string, data_interval_end: string, data_interval_start: string, end_date: string, execution_date: string, external_trigger: bool, last_scheduling_decision: string, logical_date: string, note: string, run_type: string, start_date: string, state: string>, total_entries: int>
# operationId: get_dag_runs_batch
export def "get-dag-runs-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-ids: list<string> # Return objects with specific DAG IDs. The value can be repeated to retrieve multiple matching values (OR condition).
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with end_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with end_date_gte parameter to receive only the selected period. (format: date-time)
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte key to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte key to receive only the selected period. (format: date-time)
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --page-limit: int # The numbers of items to return. (default: 100)
  --page-offset: int # The number of items to skip before starting to collect the result set.
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte key to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period (format: date-time)
  --states: list<string> # Return objects with specific states. The value can be repeated to retrieve multiple matching values (OR condition).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/~/dagRuns/list"
    body: {content_type: "application/json", kind: json, fields: [{name: dag_ids, var: dag_ids}, {name: end_date_gte, var: end_date_gte}, {name: end_date_lte, var: end_date_lte}, {name: execution_date_gte, var: execution_date_gte}, {name: execution_date_lte, var: execution_date_lte}, {name: order_by, var: order_by}, {name: page_limit, var: page_limit}, {name: page_offset, var: page_offset}, {name: start_date_gte, var: start_date_gte}, {name: start_date_lte, var: start_date_lte}, {name: states, var: states}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_ids: $dag_ids, end_date_gte: $end_date_gte, end_date_lte: $end_date_lte, execution_date_gte: $execution_date_gte, execution_date_lte: $execution_date_lte, order_by: $order_by, page_limit: $page_limit, page_offset: $page_offset, start_date_gte: $start_date_gte, start_date_lte: $start_date_lte, states: $states
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List task instances (batch)
#
# POST /dags/~/dagRuns/~/taskInstances/list
# Returns: record<task_instances: table<dag_id: string, dag_run_id: string, duration: float, end_date: string, execution_date: string, executor_config: string, hostname: string, map_index: int, max_tries: int, note: string, operator: string, pid: int, pool: string, pool_slots: int, priority_weight: int, queue: string, queued_when: string, rendered_fields: record, sla_miss: record, start_date: string, state: string, task_id: string, trigger: record, triggerer_job: record, try_number: int, unixname: string>, total_entries: int>
# operationId: get_task_instances_batch
export def "get-task-instances-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dag-ids: list<string> # Return objects with specific DAG IDs. The value can be repeated to retrieve multiple matching values (OR condition).
  --duration-gte: float # Returns objects greater than or equal to the specified values. This can be combined with duration_lte parameter to receive only the selected period.
  --duration-lte: float # Returns objects less than or equal to the specified values. This can be combined with duration_gte parameter to receive only the selected range.
  --end-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --end-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --execution-date-gte: string # Returns objects greater or equal to the specified date. This can be combined with execution_date_lte parameter to receive only the selected period. (format: date-time)
  --execution-date-lte: string # Returns objects less than or equal to the specified date. This can be combined with execution_date_gte parameter to receive only the selected period. (format: date-time)
  --pool: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --queue: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
  --start-date-gte: string # Returns objects greater or equal the specified date. This can be combined with start_date_lte parameter to receive only the selected period. (format: date-time)
  --start-date-lte: string # Returns objects less or equal the specified date. This can be combined with start_date_gte parameter to receive only the selected period. (format: date-time)
  --state: list<string> # The value can be repeated to retrieve multiple matching values (OR condition).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/dags/~/dagRuns/~/taskInstances/list"
    body: {content_type: "application/json", kind: json, fields: [{name: dag_ids, var: dag_ids}, {name: duration_gte, var: duration_gte}, {name: duration_lte, var: duration_lte}, {name: end_date_gte, var: end_date_gte}, {name: end_date_lte, var: end_date_lte}, {name: execution_date_gte, var: execution_date_gte}, {name: execution_date_lte, var: execution_date_lte}, {name: pool, var: pool}, {name: queue, var: queue}, {name: start_date_gte, var: start_date_gte}, {name: start_date_lte, var: start_date_lte}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dag_ids: $dag_ids, duration_gte: $duration_gte, duration_lte: $duration_lte, end_date_gte: $end_date_gte, end_date_lte: $end_date_lte, execution_date_gte: $execution_date_gte, execution_date_lte: $execution_date_lte, pool: $pool, queue: $queue, start_date_gte: $start_date_gte, start_date_lte: $start_date_lte, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List datasets
#
# GET /datasets
# Returns: record<datasets: table<consuming_dags: list, created_at: string, extra: record, id: int, producing_tasks: list, updated_at: string, uri: string>, total_entries: int>
# operationId: get_datasets
export def "get-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --uri-pattern: string # If set, only return datasets with uris matching this pattern.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasets"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}, {name: uri_pattern, var: uri_pattern}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by, uri_pattern: $uri_pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dataset events
#
# GET /datasets/events
# Returns: record<dataset_events: table<created_dagruns: list, dataset_id: int, dataset_uri: string, extra: record, source_dag_id: string, source_map_index: int, source_run_id: string, source_task_id: string, timestamp: string>, total_entries: int>
# operationId: get_dataset_events
export def "get-dataset-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
  --dataset-id: int # The Dataset ID that updated the dataset.
  --source-dag-id: string # The DAG ID that updated the dataset.
  --source-task-id: string # The task ID that updated the dataset.
  --source-run-id: string # The DAG run ID that updated the dataset.
  --source-map-index: int # The map index that updated the dataset.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasets/events"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}, {name: dataset_id, var: dataset_id}, {name: source_dag_id, var: source_dag_id}, {name: source_task_id, var: source_task_id}, {name: source_run_id, var: source_run_id}, {name: source_map_index, var: source_map_index}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by, dataset_id: $dataset_id, source_dag_id: $source_dag_id, source_task_id: $source_task_id, source_run_id: $source_run_id, source_map_index: $source_map_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a dataset
#
# GET /datasets/{uri}
# Returns: record<consuming_dags: table<created_at: string, dag_id: string, updated_at: string>, created_at: string, extra: record, id: int, producing_tasks: table<created_at: string, dag_id: string, task_id: string, updated_at: string>, updated_at: string, uri: string>
# operationId: get_dataset
export def "get-dataset" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/datasets/{uri}"
    path_params: [{name: uri, var: uri}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List log entries
#
# GET /eventLogs
# Returns: record<event_logs: table<dag_id: string, event: string, event_log_id: int, execution_date: string, extra: string, owner: string, task_id: string, when: string>, total_entries: int>
# operationId: get_event_logs
export def "get-event-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/eventLogs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a log entry
#
# GET /eventLogs/{event_log_id}
# Returns: record<dag_id: string, event: string, event_log_id: int, execution_date: string, extra: string, owner: string, task_id: string, when: string>
# operationId: get_event_log
export def "get-event-log" [
  event_log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/eventLogs/{event_log_id}"
    path_params: [{name: event_log_id, var: event_log_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    event_log_id: $event_log_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get instance status
#
# GET /health
# Returns: record<metadatabase: record<status: string>, scheduler: record<latest_scheduler_heartbeat: string, status: string>>
# operationId: get_health
export def "get-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/health"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List import errors
#
# GET /importErrors
# Returns: record<import_errors: table<filename: string, import_error_id: int, stack_trace: string, timestamp: string>, total_entries: int>
# operationId: get_import_errors
export def "get-import-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/importErrors"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an import error
#
# GET /importErrors/{import_error_id}
# Returns: record<filename: string, import_error_id: int, stack_trace: string, timestamp: string>
# operationId: get_import_error
export def "get-import-error" [
  import_error_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/importErrors/{import_error_id}"
    path_params: [{name: import_error_id, var: import_error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    import_error_id: $import_error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List permissions
#
# GET /permissions
# Returns: record<actions: table<name: string>, total_entries: int>
# operationId: get_permissions
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
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/permissions"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of loaded plugins
#
# GET /plugins
# Returns: record<plugins: table<appbuilder_menu_items: list, appbuilder_views: list, executors: list, flask_blueprints: list, global_operator_extra_links: list, hooks: list, macros: list, name: string, operator_extra_links: list, source: string>, total_entries: int>
# operationId: get_plugins
export def "get-plugins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/plugins"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pools
#
# GET /pools
# Returns: record<pools: table<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>, total_entries: int>
# operationId: get_pools
export def "get-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pools"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a pool
#
# POST /pools
# Returns: record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>
# operationId: post_pool
export def "post-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the pool. *New in version 2.3.0* (nullable)
  --name: string # The name of pool.
  --slots: int # The maximum number of slots that can be assigned to tasks. One job may occupy one or more slots.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pools"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: slots, var: slots}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    description: $description, name: $name, slots: $slots
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a pool
#
# DELETE /pools/{pool_name}
# operationId: delete_pool
export def "delete-pool" [
  pool_name: string
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
    path: "/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a pool
#
# GET /pools/{pool_name}
# Returns: record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>
# operationId: get_pool
export def "get-pool" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a pool
#
# PATCH /pools/{pool_name}
# Returns: record<description: string, name: string, occupied_slots: int, open_slots: int, queued_slots: int, slots: int, used_slots: int>
# operationId: patch_pool
export def "patch-pool" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --description: string # The description of the pool. *New in version 2.3.0* (nullable)
  --name: string # The name of pool.
  --slots: int # The maximum number of slots that can be assigned to tasks. One job may occupy one or more slots.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: slots, var: slots}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    pool_name: $pool_name, update_mask: $update_mask, description: $description, name: $name, slots: $slots
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List providers
#
# GET /providers
# Returns: record<providers: table<description: string, package_name: string, version: string>, total_entries: int>
# operationId: get_providers
export def "get-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/providers"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List roles
#
# GET /roles
# Returns: record<roles: table<actions: list, name: string>, total_entries: int>
# operationId: get_roles
export def "get-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a role
#
# POST /roles
# Returns: record<actions: table<action: record, resource: record>, name: string>
# operationId: post_role
export def "post-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list # item shape: {action?: record, resource?: record}
  --name: string # The name of the role *Changed in version 2.3.0*&#58; A minimum character length requirement ('minLength') is added.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: actions, var: actions}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    actions: $actions, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a role
#
# DELETE /roles/{role_name}
# operationId: delete_role
export def "delete-role" [
  role_name: string
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
    path: "/roles/{role_name}"
    path_params: [{name: role_name, var: role_name}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a role
#
# GET /roles/{role_name}
# Returns: record<actions: table<action: record, resource: record>, name: string>
# operationId: get_role
export def "get-role" [
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/roles/{role_name}"
    path_params: [{name: role_name, var: role_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    role_name: $role_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a role
#
# PATCH /roles/{role_name}
# Returns: record<actions: table<action: record, resource: record>, name: string>
# operationId: patch_role
export def "patch-role" [
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --actions: list # item shape: {action?: record, resource?: record}
  --name: string # The name of the role *Changed in version 2.3.0*&#58; A minimum character length requirement ('minLength') is added.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/roles/{role_name}"
    path_params: [{name: role_name, var: role_name}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: actions, var: actions}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    role_name: $role_name, update_mask: $update_mask, actions: $actions, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /users
# Returns: record<users: table<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: list, username: string>, total_entries: int>
# operationId: get_users
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
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a user
#
# POST /users
# Returns: record<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: table<name: string>, username: string, password: string>
# operationId: post_user
export def "post-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The user's email. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --first-name: string # The user's first name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --last-name: string # The user's last name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --roles: list # User roles. *Changed in version 2.2.0*&#58; Field is no longer read-only. — item shape: {name?: string}
  --username: string # The username. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: roles, var: roles}, {name: username, var: username}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email: $email, first_name: $first_name, last_name: $last_name, roles: $roles, username: $username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /users/{username}
# operationId: delete_user
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{username}
# Returns: record<active: bool, changed_on: string, created_on: string, email: string, failed_login_count: int, first_name: string, last_login: string, last_name: string, login_count: int, roles: table<name: string>, username: string>
# operationId: get_user
export def "get-user" [
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
    method: get
    path: "/users/{username}"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PATCH /users/{username}
# Returns: record<actions: table<action: record, resource: record>, name: string>
# operationId: patch_user
export def "patch-user" [
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
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --email: string # The user's email. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added.
  --first-name: string # The user's first name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --last-name: string # The user's last name. *Changed in version 2.4.0*&#58; The requirement for this to be non-empty was removed.
  --roles: list # User roles. *Changed in version 2.2.0*&#58; Field is no longer read-only. — item shape: {name?: string}
  --body-username: string # The username. *Changed in version 2.2.0*&#58; A minimum character length requirement ('minLength') is added. (spec name: username)
  --password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{username}"
    path_params: [{name: username, var: username}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: roles, var: roles}, {name: username, var: body_username}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    username: $username, update_mask: $update_mask, email: $email, first_name: $first_name, last_name: $last_name, roles: $roles, body_username: $body_username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables
#
# GET /variables
# Returns: record<variables: table<description: string, key: string>, total_entries: int>
# operationId: get_variables
export def "get-variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set.
  --order-by: string # The name of the field to order the results by. Prefix a field name with `-` to reverse the sort order. *New in version 2.1.0*
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variables"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: order_by, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    limit: $limit, offset: $offset, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable
#
# POST /variables
# Returns: record<description: string, key: string, value: string>
# operationId: post_variables
export def "post-variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the variable. *New in version 2.4.0* (nullable)
  --key: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/variables"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    description: $description, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable
#
# DELETE /variables/{variable_key}
# operationId: delete_variable
export def "delete-variable" [
  variable_key: string
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
    path: "/variables/{variable_key}"
    path_params: [{name: variable_key, var: variable_key}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    variable_key: $variable_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variable
#
# GET /variables/{variable_key}
# Returns: record<description: string, key: string, value: string>
# operationId: get_variable
export def "get-variable" [
  variable_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/variables/{variable_key}"
    path_params: [{name: variable_key, var: variable_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_key: $variable_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable
#
# PATCH /variables/{variable_key}
# Returns: record<description: string, key: string, value: string>
# operationId: patch_variable
export def "patch-variable" [
  variable_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: list<string> # The fields to update on the resource. If absent or empty, all modifiable fields are updated. A comma-separated list of fully qualified names of fields.
  --description: string # The description of the variable. *New in version 2.4.0* (nullable)
  --key: string
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/variables/{variable_key}"
    path_params: [{name: variable_key, var: variable_key}]
    query: [{name: update_mask, var: update_mask, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    variable_key: $variable_key, update_mask: $update_mask, description: $description, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get version information
#
# GET /version
# Returns: record<git_version: string, version: string>
# operationId: get_version
export def "get-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/version"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
