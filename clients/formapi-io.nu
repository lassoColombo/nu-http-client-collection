# Auto-generated client for API v1 v1
# Source: https://api.apis.guru/v2/specs/formapi.io/v1/openapi.json
# Auth: --token flag or $env.API_V1_TOKEN

const CLIENT = {
  base_url: "https://api.docspring.com/api/v1"
  token_env_var: "API_V1_TOKEN"
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

def base-url-completer [] { ["https://api.docspring.com/api/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def auth-second-factor-type-completer [] { ["fingerprint" "mobile_push" "none" "phone_number" "security_key" "totp"] }
def auth-type-completer [] { ["email_link" "ldap" "none" "oauth" "password" "phone_number" "saml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    test-authentication: "record<status: string>"
    list-combined-submissions: "table<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>"
    combine-submissions: "record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string>"
    expire-combined-submission: "record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>"
    get-combined-submission: "record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>"
    combine-pdfs: "record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string>"
    create-custom-file-from-upload: "record<custom_file: record<id: string, url: string>, errors: list<string>, status: string>"
    get-data-request: "record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>"
    update-data-request: "record<data_request: record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, errors: list<string>, status: string>"
    create-data-request-token: "record<errors: list<string>, status: string, token: record<data_request_url: string, expires_at: string, id: string, secret: string>>"
    list-folders: "table<id: string, name: string, parent_folder_id: string, path: string>"
    create-folder: "record<id: string, name: string, parent_folder_id: string, path: string>"
    delete-folder: "record<id: string, name: string, parent_folder_id: string, path: string>"
    move-folder-to-folder: "record<id: string, name: string, parent_folder_id: string, path: string>"
    list-submissions: "record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>"
    batch-generate-pdfs: "record<error: string, errors: list<string>, status: string, submission_batch: record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: list<record>, total_count: int>, submissions: table<errors: list, status: string, submission: record>>"
    get-submission-batch: "record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>, total_count: int>"
    expire-submission: "record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>"
    get-submission: "record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>"
    list-templates: "table<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    create-pdf-template: "record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    get-template: "record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    update-template: "record<errors: list<string>, status: string>"
    add-fields-to-template: "record<errors: list<string>, new_field_ids: list<int>, status: string>"
    copy-template: "record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    move-template-to-folder: "record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    get-template-schema: "record<\"$schema\": string, additionalProperties: bool, definitions: record, description: string, id: string, properties: record, required: list<any>, title: string, type: string>"
    get-templates-template-id-submissions: "record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>"
    generate-pdf: "record<errors: list<string>, status: string, submission: record<actions: list<record>, batch_id: string, data: record, data_requests: list<record>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>"
    batch-generate-pdf-v1: "table<errors: list<string>, status: string, submission: record<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>"
    get-full-template: "record<allow_additional_properties: bool, defaults: record<color: string, fontSize: float, typeface: string>, demo: bool, description: string, document_filename: string, document_md5: string, document_parse_error: bool, document_processed: bool, document_state: string, document_url: string, editable_submissions: bool, embed_domains: list<string>, encrypt_pdfs: bool, encrypt_pdfs_password: string, expiration_interval: string, expire_after: float, expire_submissions: bool, field_order: list<list<float>>, fields: record, first_template: bool, footer_html: string, header_html: string, html: string, id: string, locked: bool, name: string, page_count: float, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, scss: string, shared_field_data: record, slack_webhook_url: string, template_type: string, webhook_url: string>"
    create-pdf-template-from-upload: "record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    create-html-template: "record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>"
    get-presign-url: "record<fields: record<key: string, policy: string, x-amz-algorithm: string, x-amz-credential: string, x-amz-date: string, x-amz-signature: string>, headers: record, method: string, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["test-authentication" "list-combined-submissions" "combine-submissions" "expire-combined-submission" "get-combined-submission" "combine-pdfs" "create-custom-file-from-upload" "get-data-request" "update-data-request" "create-data-request-token" "list-folders" "create-folder" "delete-folder" "move-folder-to-folder" "rename-folder" "list-submissions" "batch-generate-pdfs" "get-submission-batch" "expire-submission" "get-submission" "list-templates" "create-pdf-template" "get-template" "update-template" "add-fields-to-template" "copy-template" "move-template-to-folder" "get-template-schema" "get-templates-template-id-submissions" "generate-pdf" "batch-generate-pdf-v1" "get-full-template" "create-pdf-template-from-upload" "create-html-template" "get-presign-url" "commands"] | sort) } | get name | first)
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

# Test Authentication
#
# GET /authentication
# Returns: record<status: string>
# operationId: testAuthentication
export def "test-authentication" [
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
    path: "/authentication"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all combined submissions
#
# GET /combined_submissions
# Returns: table<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>
# operationId: listCombinedSubmissions
export def "list-combined-submissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/combined_submissions"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge generated PDFs together
#
# POST /combined_submissions
# Returns: record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string>
# operationId: combineSubmissions
export def "combine-submissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expires-in: int
  --metadata: record
  --password: string
  submission_ids: list<string>
  --test: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/combined_submissions"
    body: {content_type: "application/json", kind: json, fields: [{name: expires_in, var: expires_in}, {name: metadata, var: metadata}, {name: password, var: password}, {name: submission_ids, var: submission_ids}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    expires_in: $expires_in, metadata: $metadata, password: $password, submission_ids: $submission_ids, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expire a combined submission
#
# DELETE /combined_submissions/{combined_submission_id}
# Returns: record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>
# operationId: expireCombinedSubmission
export def "expire-combined-submission" [
  combined_submission_id: string
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
    path: "/combined_submissions/{combined_submission_id}"
    path_params: [{name: combined_submission_id, var: combined_submission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    combined_submission_id: $combined_submission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the status of a combined submission (merged PDFs)
#
# GET /combined_submissions/{combined_submission_id}
# Returns: record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>
# operationId: getCombinedSubmission
export def "get-combined-submission" [
  combined_submission_id: string
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
    path: "/combined_submissions/{combined_submission_id}"
    path_params: [{name: combined_submission_id, var: combined_submission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    combined_submission_id: $combined_submission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge submission PDFs, template PDFs, or custom files
#
# POST /combined_submissions?v=2
# Returns: record<combined_submission: record<actions: list<record>, download_url: string, error_message: string, expired: bool, expires_at: string, expires_in: int, id: string, metadata: record, password: string, pdf_hash: string, source_pdfs: list<any>, state: string, submission_ids: list<string>>, errors: list<string>, status: string>
# operationId: combinePdfs
export def "combine-pdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-custom-files: oneof<nothing, bool>
  --expires-in: int
  --metadata: record
  --password: string
  source_pdfs: list
  --test: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/combined_submissions"
    fixed_query: "v=2"
    body: {content_type: "application/json", kind: json, fields: [{name: delete_custom_files, var: delete_custom_files}, {name: expires_in, var: expires_in}, {name: metadata, var: metadata}, {name: password, var: password}, {name: source_pdfs, var: source_pdfs}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    delete_custom_files: $delete_custom_files, expires_in: $expires_in, metadata: $metadata, password: $password, source_pdfs: $source_pdfs, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new custom file from a cached presign upload
#
# POST /custom_files
# Returns: record<custom_file: record<id: string, url: string>, errors: list<string>, status: string>
# operationId: createCustomFileFromUpload
export def "create-custom-file-from-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cache_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_files"
    body: {content_type: "application/json", kind: json, fields: [{name: cache_id, var: cache_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    cache_id: $cache_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Look up a submission data request
#
# GET /data_requests/{data_request_id}
# Returns: record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>
# operationId: getDataRequest
export def "get-data-request" [
  data_request_id: string
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
    path: "/data_requests/{data_request_id}"
    path_params: [{name: data_request_id, var: data_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_request_id: $data_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a submission data request
#
# PUT /data_requests/{data_request_id}
# Returns: record<data_request: record<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list<string>, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, errors: list<string>, status: string>
# operationId: updateDataRequest
export def "update-data-request" [
  data_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-phone-number-hash: string # nullable
  --auth-provider: string # nullable
  --auth-second-factor-type: string@auth-second-factor-type-completer
  --auth-session-id-hash: string # nullable
  --auth-session-started-at: string # nullable
  --auth-type: string@auth-type-completer
  --auth-user-id-hash: string # nullable
  --auth-username-hash: string # nullable
  --email: string # nullable
  --fields: list<string>
  --metadata: record
  --name: string # nullable
  --order: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/data_requests/{data_request_id}"
    path_params: [{name: data_request_id, var: data_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: auth_phone_number_hash, var: auth_phone_number_hash}, {name: auth_provider, var: auth_provider}, {name: auth_second_factor_type, var: auth_second_factor_type}, {name: auth_session_id_hash, var: auth_session_id_hash}, {name: auth_session_started_at, var: auth_session_started_at}, {name: auth_type, var: auth_type}, {name: auth_user_id_hash, var: auth_user_id_hash}, {name: auth_username_hash, var: auth_username_hash}, {name: email, var: email}, {name: fields, var: fields}, {name: metadata, var: metadata}, {name: name, var: name}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_request_id: $data_request_id, auth_phone_number_hash: $auth_phone_number_hash, auth_provider: $auth_provider, auth_second_factor_type: $auth_second_factor_type, auth_session_id_hash: $auth_session_id_hash, auth_session_started_at: $auth_session_started_at, auth_type: $auth_type, auth_user_id_hash: $auth_user_id_hash, auth_username_hash: $auth_username_hash, email: $email, fields: $fields, metadata: $metadata, name: $name, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new data request token for form authentication
#
# POST /data_requests/{data_request_id}/tokens
# Returns: record<errors: list<string>, status: string, token: record<data_request_url: string, expires_at: string, id: string, secret: string>>
# operationId: createDataRequestToken
export def "create-data-request-token" [
  data_request_id: string
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
    path: "/data_requests/{data_request_id}/tokens"
    path_params: [{name: data_request_id, var: data_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    data_request_id: $data_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all folders
#
# GET /folders/
# Returns: table<id: string, name: string, parent_folder_id: string, path: string>
# operationId: listFolders
export def "list-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000002)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/folders/"
    query: [{name: parent_folder_id, var: parent_folder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a folder
#
# POST /folders/
# Returns: record<id: string, name: string, parent_folder_id: string, path: string>
# operationId: createFolder
export def "create-folder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  folder: record # shape: {name: string, parent_folder_id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/"
    body: {content_type: "application/json", kind: json, fields: [{name: folder, var: folder}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    folder: $folder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a folder
#
# DELETE /folders/{folder_id}
# Returns: record<id: string, name: string, parent_folder_id: string, path: string>
# operationId: deleteFolder
export def "delete-folder" [
  folder_id: string
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
    path: "/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move a folder
#
# POST /folders/{folder_id}/move
# Returns: record<id: string, name: string, parent_folder_id: string, path: string>
# operationId: moveFolderToFolder
export def "move-folder-to-folder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-folder-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}/move"
    path_params: [{name: folder_id, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: parent_folder_id, var: parent_folder_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    folder_id: $folder_id, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a folder
#
# POST /folders/{folder_id}/rename
# operationId: renameFolder
export def "rename-folder" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/folders/{folder_id}/rename"
    path_params: [{name: folder_id, var: folder_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    folder_id: $folder_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all submissions
#
# GET /submissions
# Returns: record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>
# operationId: listSubmissions
export def "list-submissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # e.g. sub_list_000012
  --limit: float # e.g. 3
  --created-after: string # e.g. 2019-01-01T09:00:00-05:00
  --created-before: string # e.g. 2020-01-01T09:00:00-05:00
  --type: string # e.g. test
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/submissions"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: created_after, var: created_after}, {name: created_before, var: created_before}, {name: type, var: type}, {name: include_data, var: include_data}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    cursor: $cursor, limit: $limit, created_after: $created_after, created_before: $created_before, type: $type, include_data: $include_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates multiple PDFs
#
# POST /submissions/batches
# Returns: record<error: string, errors: list<string>, status: string, submission_batch: record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: list<record>, total_count: int>, submissions: table<errors: list, status: string, submission: record>>
# operationId: batchGeneratePdfs
export def "batch-generate-pdfs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record
  submissions: list # item shape: {css?: string, data: record, html?: string, metadata?: record, template_id: string, test?: bool}
  --template-id: string # nullable
  --test: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/submissions/batches"
    body: {content_type: "application/json", kind: json, fields: [{name: metadata, var: metadata}, {name: submissions, var: submissions}, {name: template_id, var: template_id}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: basic
  } {
    metadata: $metadata, submissions: $submissions, template_id: $template_id, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the status of a submission batch job
#
# GET /submissions/batches/{submission_batch_id}
# Returns: record<completion_percentage: int, error_count: int, id: string, metadata: record, pending_count: int, processed_at: string, state: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>, total_count: int>
# operationId: getSubmissionBatch
export def "get-submission-batch" [
  submission_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-submissions: oneof<nothing, bool> # e.g. true
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/submissions/batches/{submission_batch_id}"
    path_params: [{name: submission_batch_id, var: submission_batch_id}]
    query: [{name: include_submissions, var: include_submissions}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    submission_batch_id: $submission_batch_id, include_submissions: $include_submissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expire a PDF submission
#
# DELETE /submissions/{submission_id}
# Returns: record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>
# operationId: expireSubmission
export def "expire-submission" [
  submission_id: string
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
    path: "/submissions/{submission_id}"
    path_params: [{name: submission_id, var: submission_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    submission_id: $submission_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the status of a PDF
#
# GET /submissions/{submission_id}
# Returns: record<actions: table<action_category: string, action_type: string, id: string, integration_id: string, result_data: record, state: string>, batch_id: string, data: record, data_requests: table<auth_phone_number_hash: string, auth_provider: string, auth_second_factor_type: string, auth_session_id_hash: string, auth_session_started_at: string, auth_type: string, auth_user_id_hash: string, auth_username_hash: string, completed_at: string, email: string, fields: list, id: string, ip_address: string, metadata: record, name: string, order: int, sort_order: int, state: string, submission_id: string, user_agent: string, viewed_at: string>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>
# operationId: getSubmission
export def "get-submission" [
  submission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/submissions/{submission_id}"
    path_params: [{name: submission_id, var: submission_id}]
    query: [{name: include_data, var: include_data}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    submission_id: $submission_id, include_data: $include_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all templates
#
# GET /templates
# Returns: table<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: listTemplates
export def "list-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search By Name (e.g. 2)
  --parent-folder-id: string # Filter By Folder Id (e.g. fld_000000000000000001)
  --page: int # Default: 1 (e.g. 2)
  --per-page: int # Default: 50 (e.g. 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/templates"
    query: [{name: query, var: query}, {name: parent_folder_id, var: parent_folder_id}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    query: $query, parent_folder_id: $parent_folder_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new PDF template with a form POST file upload
#
# POST /templates
# Returns: record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: createPDFTemplate
export def "create-pdf-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template_document: string # format: binary, e.g. <Uploaded File>
  template_name: string # e.g. Test Template
  --template-parent-folder-id: string # e.g. fld_000000000000000001
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: "template[document]", var: template_document}, {name: "template[name]", var: template_name}, {name: "template[parent_folder_id]", var: template_parent_folder_id}], files: ["template[document]"]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template_document: $template_document, template_name: $template_name, template_parent_folder_id: $template_parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the status of an uploaded template
#
# GET /templates/{template_id}
# Returns: record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: getTemplate
export def "get-template" [
  template_id: string
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
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Template
#
# PUT /templates/{template_id}
# Returns: record<errors: list<string>, status: string>
# operationId: updateTemplate
export def "update-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name?: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, webhook_url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: template, var: template}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new fields to a Template
#
# PUT /templates/{template_id}/add_fields
# Returns: record<errors: list<string>, new_field_ids: list<int>, status: string>
# operationId: addFieldsToTemplate
export def "add-fields-to-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: list # item shape: {alignment?: "left"|"center"|"right", autoCalculateMaxLength?: bool, backgroundColor?: string, backgroundColorFieldName?: string, backgroundColorFieldRequired?: bool, barcodeSymbology?: string, bold?: bool, characterSpacing?: float, checkCharacter?: "&#10003;"|"&#10004;"|"&#10006;"|"&#10007;"|"&#10008;", checkColor?: string, checkColorFieldName?: string, checkColorFieldRequired?: bool, color?: string, colorFieldName?: string, colorFieldRequired?: bool, comb?: bool, combNumberOfCells?: float, ... (69 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/templates/{template_id}/add_fields"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy a Template
#
# POST /templates/{template_id}/copy
# Returns: record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: copyTemplate
export def "copy-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  parent_folder_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}/copy"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent_folder_id, var: parent_folder_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, name: $name, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move Template to folder
#
# POST /templates/{template_id}/move
# Returns: record<allow_additional_properties: bool, description: string, document_url: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: moveTemplateToFolder
export def "move-template-to-folder" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parent_folder_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}/move"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: parent_folder_id, var: parent_folder_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the JSON schema for a template
#
# GET /templates/{template_id}/schema
# Returns: record<"$schema": string, additionalProperties: bool, definitions: record, description: string, id: string, properties: record, required: list<any>, title: string, type: string>
# operationId: getTemplateSchema
export def "get-template-schema" [
  template_id: string
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
    path: "/templates/{template_id}/schema"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all submissions for a given template
#
# GET /templates/{template_id}/submissions
# Returns: record<limit: float, next_cursor: string, submissions: table<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>
export def "get-templates-template-id-submissions" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: float
  --created-after: string
  --created-before: string
  --type: string
  --include-data: oneof<nothing, bool> # e.g. true
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{template_id}/submissions"
    path_params: [{name: template_id, var: template_id}]
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: created_after, var: created_after}, {name: created_before, var: created_before}, {name: type, var: type}, {name: include_data, var: include_data}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, cursor: $cursor, limit: $limit, created_after: $created_after, created_before: $created_before, type: $type, include_data: $include_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a new PDF
#
# POST /templates/{template_id}/submissions
# Returns: record<errors: list<string>, status: string, submission: record<actions: list<record>, batch_id: string, data: record, data_requests: list<record>, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>
# operationId: generatePDF
export def "generate-pdf" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
  --expires-in: int
  --field-overrides: record
  --html: string
  --metadata: record
  --password: string
  --test: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}/submissions"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: css, var: css}, {name: data, var: data}, {name: data_requests, var: data_requests}, {name: expires_in, var: expires_in}, {name: field_overrides, var: field_overrides}, {name: html, var: html}, {name: metadata, var: metadata}, {name: password, var: password}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template_id: $template_id, css: $css, data: $data, data_requests: $data_requests, expires_in: $expires_in, field_overrides: $field_overrides, html: $html, metadata: $metadata, password: $password, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates multiple PDFs
#
# POST /templates/{template_id}/submissions/batch
# Returns: table<errors: list<string>, status: string, submission: record<actions: list, batch_id: string, data: record, data_requests: list, download_url: string, editable: bool, expired: bool, expires_at: string, id: string, metadata: record, pdf_hash: string, permanent_download_url: string, processed_at: string, referrer: string, source: string, state: string, template_id: string, test: bool, truncated_text: record>>
# operationId: batchGeneratePdfV1
export def "batch-generate-pdf-v1" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  data: record
  --data-requests: list # item shape: {auth_phone_number_hash?: string, auth_provider?: string, auth_second_factor_type?: "none"|"phone_number"|"totp"|"mobile_push"|"security_key"|"fingerprint", auth_session_id_hash?: string, auth_session_started_at?: string, auth_type: "none"|"password"|"oauth"|"email_link"|"phone_number"|"ldap"|"saml", auth_user_id_hash?: string, auth_username_hash?: string, email: string, fields?: list<string>, metadata?: record, name?: string, order?: int}
  --html: string
  --metadata: record
  --test: oneof<nothing, bool>
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}/submissions/batch"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar, fields: [{name: css, var: css}, {name: data, var: data}, {name: data_requests, var: data_requests}, {name: html, var: html}, {name: metadata, var: metadata}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template_id: $template_id, css: $css, data: $data, data_requests: $data_requests, html: $html, metadata: $metadata, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch the full template attributes
#
# GET /templates/{template_id}?full=true
# Returns: record<allow_additional_properties: bool, defaults: record<color: string, fontSize: float, typeface: string>, demo: bool, description: string, document_filename: string, document_md5: string, document_parse_error: bool, document_processed: bool, document_state: string, document_url: string, editable_submissions: bool, embed_domains: list<string>, encrypt_pdfs: bool, encrypt_pdfs_password: string, expiration_interval: string, expire_after: float, expire_submissions: bool, field_order: list<list<float>>, fields: record, first_template: bool, footer_html: string, header_html: string, html: string, id: string, locked: bool, name: string, page_count: float, page_dimensions: list<list<float>>, parent_folder_id: string, path: string, permanent_document_url: string, public_submissions: bool, public_web_form: bool, redirect_url: string, scss: string, shared_field_data: record, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: getFullTemplate
export def "get-full-template" [
  template_id: string
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
    path: "/templates/{template_id}"
    fixed_query: "full=true"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new PDF template from a cached presign upload
#
# POST /templates?desc=cached_upload
# Returns: record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: createPDFTemplateFromUpload
export def "create-pdf-template-from-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, document?: record, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates"
    fixed_query: "desc=cached_upload"
    body: {content_type: "application/json", kind: json, fields: [{name: template, var: template}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new HTML template
#
# POST /templates?desc=html
# Returns: record<allow_additional_properties: bool, description: string, editable_submissions: bool, expiration_interval: string, expire_after: float, expire_submissions: bool, id: string, locked: bool, name: string, parent_folder_id: string, path: string, public_submissions: bool, public_web_form: bool, redirect_url: string, slack_webhook_url: string, template_type: string, webhook_url: string>
# operationId: createHTMLTemplate
export def "create-html-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template: record # shape: {allow_additional_properties?: bool, description?: string, editable_submissions?: bool, expiration_interval?: "minutes"|"hours"|"days", expire_after?: float, expire_submissions?: bool, footer_html?: string, header_html?: string, html?: string, name: string, public_submissions?: bool, public_web_form?: bool, redirect_url?: string, scss?: string, slack_webhook_url?: string, template_type?: "pdf"|"html", webhook_url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates"
    fixed_query: "desc=html"
    body: {content_type: "application/json", kind: json, fields: [{name: template, var: template}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a presigned URL so that you can upload a file to our AWS S3 bucket
#
# GET /uploads/presign
# Returns: record<fields: record<key: string, policy: string, x-amz-algorithm: string, x-amz-credential: string, x-amz-date: string, x-amz-signature: string>, headers: record, method: string, url: string>
# operationId: getPresignUrl
export def "get-presign-url" [
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
    path: "/uploads/presign"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
