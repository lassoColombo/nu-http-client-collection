# Auto-generated client for ClickSend REST API v3 v1.0.0
# Source: https://api.apis.guru/v2/specs/clicksend.com/1.0.0/openapi.json
# Auth: --token flag or $env.CLICKSEND_REST_API_V3_TOKEN

const CLIENT = {
  base_url: "https://rest.clicksend.com/v3"
  token_env_var: "CLICKSEND_REST_API_V3_TOKEN"
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

def base-url-completer [] { ["https://rest.clicksend.com/v3"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "create-a-new-account" "update-account" "send-account-activation-token" "verify-new-account" "account-usage" "get-automations-email-receipt" "post-automations-email-receipt" "delete-automations-email-receipt-rule-id" "get-automations-email-receipt-rule-id" "put-automations-email-receipt-rule-id" "get-automations-fax-inbound" "post-automations-fax-inbound" "delete-automations-fax-inbound-inbound-rule-id" "get-automations-fax-inbound-inbound-rule-id" "put-automations-fax-inbound-inbound-rule-id" "list-rules" "create-a-new-rule" "delete-a-rule" "get-a-specific-rule" "update-a-rule" "list-rules-1" "create-a-new-rule-1" "delete-a-rule-1" "get-a-specific-rule-1" "update-a-rule-1" "get-automations-sms-receipts" "post-automations-sms-receipts" "delete-automations-sms-receipts-receipt-rule-id" "get-automations-sms-receipts-receipt-rule-id" "put-automations-sms-receipts-receipt-rule-id" "get-automations-voice-receipts" "post-automations-voice-receipts" "delete-automations-voice-receipts-receipt-rule-id" "get-automations-voice-receipts-receipt-rule-id" "put-automations-voice-receipts-receipt-rule-id" "list-contact-suggestions" "get-all-countries" "get-delivery-issues" "create-delivery-issue" "get-all-email-campaigns" "calculate-price" "create-email-campaign" "get-specific-email-campaign-history" "get-specific-email-campaign" "update-email-campaign" "cancel-email-campaign" "send-verification-token" "verify-allowed-email-address" "get-all-allowed-email-addresses" "create-allowed-email-address" "delete-allowed-email-address" "get-specific-allowed-email-address" "email-history" "export-history" "get-all-master-email-templates" "get-all-master-template-categories" "get-specific-email-template-category" "get-all-templates-for-category" "get-specific-master-template" "email-price" "post-email-receipts" "email-send" "get-all-email-templates" "create-new-email-template-from-master-template" "upload-image-to-specific-template" "delete-email-template" "get-specific-email-template" "update-an-email-template" "export-fax-history" "get-fax-history" "post-fax-price" "list-of-fax-delivery-receipts" "add-a-test-delivery-receipt" "mark-fax-delivery-receipts-as-read" "get-a-specific-fax-delivery-receipt" "send-fax" "forgot-password" "verify-forgot-password" "forgot-username" "get-all-contact-lists" "create-a-new-contact-list" "transfer-a-contact" "delete-a-specific-contact-list" "get-a-specific-contact-list" "update-a-specific-contact-list" "get-all-contacts-in-a-list" "create-a-new-contact" "delete-a-specific-contact" "get-a-specific-contact" "update-a-specific-contact" "export-contacts-list" "import-contacts-to-list" "show-csv-import-file-preview" "get-list-of-acceptable-import-fields" "remove-duplicate-contacts" "remove-opted-out-contacts" "cancel-all-mms" "export-mms-history" "get-mms-history" "get-price" "get-all-delivery-receipts" "mark-receipts-as-read" "get-delivery-receipt" "send-mms" "cancel-mms" "get-all-dedicated-numbers" "buy-dedicated-number" "search-dedicated-numbers-by-country" "list-direct-mail-campaigns" "calculate-direct-mail-campaign-price" "create-new-campaign" "search-locations" "detect-address" "get-post-letter-history" "export-post-letter-history" "post-post-letters-price" "send-post-letter" "export-postcard-history" "get-postcard-history" "calculate-pricing" "send-postcard" "get-list-of-post-return-addresses" "create-a-post-return-address" "delete-post-return-address" "get-post-return-address" "update-post-return-address" "get-country-pricing" "get-credit-card-info" "update-credit-card-info" "list-of-packages" "purchase-a-package" "get-transactions" "get-a-specific-transaction" "get-list-of-referral-accounts" "get-reseller-setting" "update-reseller-setting" "list-of-reseller-accounts" "create-reseller-account" "create-reseller-account-public" "get-reseller-account" "update-reseller-account" "transfer-credit" "reseller-by-subdomain" "sdk-download" "search-contacts-lists" "get-list-of-sms-campaigns" "calculate-price-for-sms-campaign" "use-short-url" "link-tracking-export" "link-statistics" "link-tracking" "get-sms-campaign" "update-an-sms-campaign" "cancel-an-sms-campaign" "cancel-all-scheduled-messages" "list-of-email-to-sms-allowed-address" "create-email-to-sms-allowed-address" "list-stripped-strings" "create-stripped-string" "delete-stripped-string" "find-specific-stripped-string" "update-stripped-string" "delete-email-to-sms-allowed-address" "get-specific-email-to-sms-allowed-address" "update-email-to-sms-allowed-address" "export-sms-history" "get-all-history" "get-all-inbound-sms-pull" "add-a-test-inbound-sms" "mark-all-inbound-sms-as-read" "mark-a-specific-inbound-sms-as-read" "get-specific-inbound-pull" "post-sms-price" "get-sms-receipts" "post-sms-receipts" "mark-delivery-receipts-as-read" "get-a-specific-delivery-receipt" "send-an-sms" "list-of-templates" "create-a-template" "delete-a-template" "update-a-template" "cancel-a-scheduled-message" "get-sms-statistics" "get-voice-statistics" "get-all-subaccounts" "create-a-new-subaccount" "delete-a-specific-subaccount" "get-a-specific-subaccount" "update-a-specific-subaccount" "regenerate-api-key" "get-timezones" "upload-a-file" "cancel-all-voice-calls" "export-voice-history" "get-voice-history" "voice-languages" "post-voice-price" "get-voice-receipts" "post-voice-receipts" "marked-voice-receipts-as-read" "get-specific-voice-receipt" "send-a-voice-call" "cancel-a-specific-voice-call" "commands"] | sort) } | get name | first)
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

# Get account
#
# GET /account
# operationId: Get account
export def "get-account" [
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
    path: "/account"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new account
#
# POST /account
# operationId: Create a new account
export def "create-a-new-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # Your delivery to value.
  country: string # Your country.
  password: string # Your password.
  user_email: string # Your email.
  user_first_name: string # Your first name.
  user_last_name: string # Your last name.
  user_phone: string # Your phone number in E.164 format.
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: post
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: country, var: country}, {name: password, var: password}, {name: user_email, var: user_email}, {name: user_first_name, var: user_first_name}, {name: user_last_name, var: user_last_name}, {name: user_phone, var: user_phone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_name: $account_name, country: $country, password: $password, user_email: $user_email, user_first_name: $user_first_name, user_last_name: $user_last_name, user_phone: $user_phone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account
#
# PUT /account
# operationId: Update Account
export def "update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # Your delivery to value.
  country: string # Your country.
  password: string # Your password.
  --private-uploads: float # Set the private uploads flag. 0 or 1 only.
  --setting-sms-hide-business-name: float # Set the private uploads flag. 0 or 1 only.
  --setting-sms-hide-your-number: float # Set the private uploads flag. 0 or 1 only.
  timezone: string # Timezone.
  user_email: string # Your email.
  user_first_name: string # Your first name.
  user_last_name: string # Your last name.
  user_phone: string # Your phone number in E.164 format.
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: put
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: country, var: country}, {name: password, var: password}, {name: private_uploads, var: private_uploads}, {name: setting_sms_hide_business_name, var: setting_sms_hide_business_name}, {name: setting_sms_hide_your_number, var: setting_sms_hide_your_number}, {name: timezone, var: timezone}, {name: user_email, var: user_email}, {name: user_first_name, var: user_first_name}, {name: user_last_name, var: user_last_name}, {name: user_phone, var: user_phone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_name: $account_name, country: $country, password: $password, private_uploads: $private_uploads, setting_sms_hide_business_name: $setting_sms_hide_business_name, setting_sms_hide_your_number: $setting_sms_hide_your_number, timezone: $timezone, user_email: $user_email, user_first_name: $user_first_name, user_last_name: $user_last_name, user_phone: $user_phone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send account activation token
#
# PUT /account-verify/send
# operationId: Send account activation token
export def "send-account-activation-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string
  --type: string
  --user-phone: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/account-verify/send"
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: type, var: type}, {name: user_phone, var: user_phone}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country, type: $type, user_phone: $user_phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify new account
#
# PUT /account-verify/verify/{activation_token}
# operationId: Verify new account
export def "verify-new-account" [
  activation_token: string
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
    method: put
    path: "/account-verify/verify/{activation_token}"
    path_params: [{name: activation_token, var: activation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    activation_token: $activation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Account Usage
#
# GET /account/usage/{year}/{month}/{type}
# operationId: Account Usage
export def "account-usage" [
  year: float
  month: float
  type: string
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
    path: "/account/usage/{year}/{month}/{type}"
    path_params: [{name: year, var: year}, {name: month, var: month}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    year: $year, month: $month, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Rules
#
# GET /automations/email/receipt
export def "get-automations-email-receipt" [
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
    path: "/automations/email/receipt"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a New Rule
#
# POST /automations/email/receipt
export def "post-automations-email-receipt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/email/receipt"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Rule
#
# DELETE /automations/email/receipt/{rule_id}
export def "delete-automations-email-receipt-rule-id" [
  rule_id: float
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
    path: "/automations/email/receipt/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Specific Rule
#
# GET /automations/email/receipt/{rule_id}
export def "get-automations-email-receipt-rule-id" [
  rule_id: float
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
    path: "/automations/email/receipt/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Rule
#
# PUT /automations/email/receipt/{rule_id}
export def "put-automations-email-receipt-rule-id" [
  rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Action.
  --action-address: string # Action Address.
  --enabled: float # Enabled.
  --match-type: float # Match Type. 0=All reports.
  --rule-name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/email/receipt/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /automations/fax/inbound
export def "get-automations-fax-inbound" [
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
    path: "/automations/fax/inbound"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new rule
#
# POST /automations/fax/inbound
export def "post-automations-fax-inbound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action
  action_address: string # Action Address
  dedicated_number: string # Decicated Number
  enabled: float # Enable
  rule_name: string # Rule Name
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/fax/inbound"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: dedicated_number, var: dedicated_number}, {name: enabled, var: enabled}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, dedicated_number: $dedicated_number, enabled: $enabled, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /automations/fax/inbound/{inbound_rule_id}
export def "delete-automations-fax-inbound-inbound-rule-id" [
  inbound_rule_id: float
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
    path: "/automations/fax/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific rule
#
# GET /automations/fax/inbound/{inbound_rule_id}
export def "get-automations-fax-inbound-inbound-rule-id" [
  inbound_rule_id: float
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
    path: "/automations/fax/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule
#
# PUT /automations/fax/inbound/{inbound_rule_id}
export def "put-automations-fax-inbound-inbound-rule-id" [
  inbound_rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action
  action_address: string # Action Address
  dedicated_number: string # Decicated Number
  enabled: float # Enable
  rule_name: string # Rule Name
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/fax/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: dedicated_number, var: dedicated_number}, {name: enabled, var: enabled}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id, action: $action, action_address: $action_address, dedicated_number: $dedicated_number, enabled: $enabled, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Rules
#
# GET /automations/fax/receipts
# operationId: List Rules
export def "list-rules" [
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
    path: "/automations/fax/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a New Rule
#
# POST /automations/fax/receipts
# operationId: Create a New Rule
export def "create-a-new-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/fax/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Rule
#
# DELETE /automations/fax/receipts/{rule_id}
# operationId: Delete a Rule
export def "delete-a-rule" [
  rule_id: float
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
    path: "/automations/fax/receipts/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Specific Rule
#
# GET /automations/fax/receipts/{rule_id}
# operationId: Get a Specific Rule
export def "get-a-specific-rule" [
  rule_id: float
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
    path: "/automations/fax/receipts/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Rule
#
# PUT /automations/fax/receipts/{rule_id}
# operationId: Update a Rule
export def "update-a-rule" [
  rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # Action.
  --action-address: string # Action Address.
  --enabled: float # Enabled.
  --match-type: float # Match Type. 0=All reports.
  --rule-name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/fax/receipts/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /automations/sms/inbound
# operationId: List rules
export def "list-rules-1" [
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
    path: "/automations/sms/inbound"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new rule
#
# POST /automations/sms/inbound/
# operationId: Create a new rule
export def "create-a-new-rule-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  dedicated_number: float # Dedicated Number.
  enabled: float # Enabled.
  message_search_term: string # Message Search Term.
  message_search_type: float # Message Search Type: 0=Any message, 1=starts with, 2=contains, 3=does not contain.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/sms/inbound/"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: dedicated_number, var: dedicated_number}, {name: enabled, var: enabled}, {name: message_search_term, var: message_search_term}, {name: message_search_type, var: message_search_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, dedicated_number: $dedicated_number, enabled: $enabled, message_search_term: $message_search_term, message_search_type: $message_search_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /automations/sms/inbound/{inbound_rule_id}
# operationId: Delete a rule
export def "delete-a-rule-1" [
  inbound_rule_id: float
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
    path: "/automations/sms/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific rule
#
# GET /automations/sms/inbound/{inbound_rule_id}
# operationId: Get a specific rule
export def "get-a-specific-rule-1" [
  inbound_rule_id: float
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
    path: "/automations/sms/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule
#
# PUT /automations/sms/inbound/{inbound_rule_id}
# operationId: Update a rule
export def "update-a-rule-1" [
  inbound_rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  dedicated_number: string # Dedicated Number
  enabled: float # Enabled.
  message_search_term: string # Message Search Term.
  message_search_type: float # Message Search Type: 0=Any message, 1=starts with, 2=contains, 3=does not contain.
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/sms/inbound/{inbound_rule_id}"
    path_params: [{name: inbound_rule_id, var: inbound_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: dedicated_number, var: dedicated_number}, {name: enabled, var: enabled}, {name: message_search_term, var: message_search_term}, {name: message_search_type, var: message_search_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    inbound_rule_id: $inbound_rule_id, action: $action, action_address: $action_address, dedicated_number: $dedicated_number, enabled: $enabled, message_search_term: $message_search_term, message_search_type: $message_search_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /automations/sms/receipts
export def "get-automations-sms-receipts" [
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
    path: "/automations/sms/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new rule
#
# POST /automations/sms/receipts
export def "post-automations-sms-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports, 1=Only failed, 2=Only successful.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/sms/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /automations/sms/receipts/{receipt_rule_id}
export def "delete-automations-sms-receipts-receipt-rule-id" [
  receipt_rule_id: float
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
    path: "/automations/sms/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific rule
#
# GET /automations/sms/receipts/{receipt_rule_id}
export def "get-automations-sms-receipts-receipt-rule-id" [
  receipt_rule_id: float
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
    path: "/automations/sms/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule
#
# PUT /automations/sms/receipts/{receipt_rule_id}
export def "put-automations-sms-receipts-receipt-rule-id" [
  receipt_rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports, 1=Only failed, 2=Only successful.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/sms/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id, action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /automations/voice/receipts
export def "get-automations-voice-receipts" [
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
    path: "/automations/voice/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new rule
#
# POST /automations/voice/receipts
export def "post-automations-voice-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports, 1=Only failed, 2=Only successful.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/automations/voice/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /automations/voice/receipts/{receipt_rule_id}
export def "delete-automations-voice-receipts-receipt-rule-id" [
  receipt_rule_id: float
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
    path: "/automations/voice/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific rule
#
# GET /automations/voice/receipts/{receipt_rule_id}
export def "get-automations-voice-receipts-receipt-rule-id" [
  receipt_rule_id: float
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
    path: "/automations/voice/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule
#
# PUT /automations/voice/receipts/{receipt_rule_id}
export def "put-automations-voice-receipts-receipt-rule-id" [
  receipt_rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Action.
  action_address: string # Action Address.
  enabled: float # Enabled.
  match_type: float # Match Type. 0=All reports, 1=Only failed, 2=Only successful.
  rule_name: string # Rule Name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/automations/voice/receipts/{receipt_rule_id}"
    path_params: [{name: receipt_rule_id, var: receipt_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: action_address, var: action_address}, {name: enabled, var: enabled}, {name: match_type, var: match_type}, {name: rule_name, var: rule_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    receipt_rule_id: $receipt_rule_id, action: $action, action_address: $action_address, enabled: $enabled, match_type: $match_type, rule_name: $rule_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Contact Suggestions
#
# GET /contact-suggestions
# operationId: List Contact Suggestions
export def "list-contact-suggestions" [
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
    path: "/contact-suggestions"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Countries
#
# GET /countries
# operationId: Get all Countries
export def "get-all-countries" [
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
    path: "/countries"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Delivery Issues
#
# GET /delivery-issues
# operationId: Get Delivery Issues
export def "get-delivery-issues" [
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
    path: "/delivery-issues"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Delivery Issue
#
# POST /delivery-issues
# operationId: Create Delivery Issue
export def "create-delivery-issue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-comments: string # The user's comments.
  description: string # The description of the message.
  email_address: string # The user's email address.
  message_id: string # The message id of the message.
  type: string # The type of message, must be one of the following values: `SMS`, `MMS`, `VOICE`, `EMAIL_MARKETING`, `EMAIL_TRANSACTIONAL`, `FAX`, `POST`.
]: any -> any {
  $in | http-request {
    method: post
    path: "/delivery-issues"
    body: {content_type: "application/json", kind: json, fields: [{name: client_comments, var: client_comments}, {name: description, var: description}, {name: email_address, var: email_address}, {name: message_id, var: message_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    client_comments: $client_comments, description: $description, email_address: $email_address, message_id: $message_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Email Campaigns
#
# GET /email-campaigns
# operationId: Get All Email Campaigns
export def "get-all-email-campaigns" [
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
    path: "/email-campaigns"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price
#
# POST /email-campaigns/price
# operationId: Calculate Price
export def "calculate-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  from_email_address_id: float # The allowed email address id.
  from_name: string # The name that will appear on the email.
  list_id: float # The list id you want to access.
  name: string # The name of the sender.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  subject: string # The subject of the email campaign.
  template_id: float # The template id you want to use.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email-campaigns/price"
    body: {content_type: "application/json", kind: json, fields: [{name: from_email_address_id, var: from_email_address_id}, {name: from_name, var: from_name}, {name: list_id, var: list_id}, {name: name, var: name}, {name: schedule, var: schedule}, {name: subject, var: subject}, {name: template_id, var: template_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    from_email_address_id: $from_email_address_id, from_name: $from_name, list_id: $list_id, name: $name, schedule: $schedule, subject: $subject, template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Email Campaign
#
# POST /email-campaigns/send
# operationId: Create Email Campaign
export def "create-email-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  from_email_address_id: float # The allowed email address id.
  from_name: string # The name that will appear on the email.
  list_id: float # The list id you want to access.
  name: string # The name of the sender.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  subject: string # The subject of the email campaign.
  template_id: float # The template id you want to use.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email-campaigns/send"
    body: {content_type: "application/json", kind: json, fields: [{name: from_email_address_id, var: from_email_address_id}, {name: from_name, var: from_name}, {name: list_id, var: list_id}, {name: name, var: name}, {name: schedule, var: schedule}, {name: subject, var: subject}, {name: template_id, var: template_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    from_email_address_id: $from_email_address_id, from_name: $from_name, list_id: $list_id, name: $name, schedule: $schedule, subject: $subject, template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Email Campaign History
#
# GET /email-campaigns/{campaign_id}/history
# operationId: Get Specific Email Campaign History
export def "get-specific-email-campaign-history" [
  campaign_id: float
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
    path: "/email-campaigns/{campaign_id}/history"
    path_params: [{name: campaign_id, var: campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    campaign_id: $campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Email Campaign
#
# GET /email-campaigns/{email_campaign_id}
# operationId: Get Specific Email Campaign
export def "get-specific-email-campaign" [
  email_campaign_id: float
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
    path: "/email-campaigns/{email_campaign_id}"
    path_params: [{name: email_campaign_id, var: email_campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_campaign_id: $email_campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Email Campaign
#
# PUT /email-campaigns/{email_campaign_id}
# operationId: Update Email Campaign
export def "update-email-campaign" [
  email_campaign_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-email-address-id: float # The allowed email address id.
  --from-name: string # The name that will appear on the email.
  --list-id: float # The list id you want to access.
  --name: string # The name of the sender.
  --schedule: float # Leave blank for immediate delivery. Will replace existing schedule (even if left blank). Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --subject: string # The subject of the email campaign.
  --template-id: float # The template id you want to use.
]: any -> any {
  $in | http-request {
    method: put
    path: "/email-campaigns/{email_campaign_id}"
    path_params: [{name: email_campaign_id, var: email_campaign_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: from_email_address_id, var: from_email_address_id}, {name: from_name, var: from_name}, {name: list_id, var: list_id}, {name: name, var: name}, {name: schedule, var: schedule}, {name: subject, var: subject}, {name: template_id, var: template_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_campaign_id: $email_campaign_id, from_email_address_id: $from_email_address_id, from_name: $from_name, list_id: $list_id, name: $name, schedule: $schedule, subject: $subject, template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel Email Campaign
#
# PUT /email-campaigns/{email_campaign_id}/cancel
# operationId: Cancel Email Campaign
export def "cancel-email-campaign" [
  email_campaign_id: float
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
    method: put
    path: "/email-campaigns/{email_campaign_id}/cancel"
    path_params: [{name: email_campaign_id, var: email_campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_campaign_id: $email_campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Verification Token
#
# PUT /email/address-verify/{email_address_id}/send
# operationId: Send Verification Token
export def "send-verification-token" [
  email_address_id: float
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
    method: put
    path: "/email/address-verify/{email_address_id}/send"
    path_params: [{name: email_address_id, var: email_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Allowed Email Address
#
# PUT /email/address-verify/{email_address_id}/verify/{activation_token}
# operationId: Verify Allowed Email Address
export def "verify-allowed-email-address" [
  email_address_id: float
  activation_token: string
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
    method: put
    path: "/email/address-verify/{email_address_id}/verify/{activation_token}"
    path_params: [{name: email_address_id, var: email_address_id}, {name: activation_token, var: activation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id, activation_token: $activation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Allowed Email Addresses
#
# GET /email/addresses
# operationId: Get All Allowed Email Addresses
export def "get-all-allowed-email-addresses" [
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
    path: "/email/addresses"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Allowed Email Address
#
# POST /email/addresses
# operationId: Create Allowed Email Address
export def "create-allowed-email-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # { "email_address" : "test222@user.com" }
  email_address: string # Your email.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/addresses"
    body: {content_type: "application/json", kind: json, fields: [{name: Body, var: body}, {name: email_address, var: email_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, email_address: $email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Allowed Email Address
#
# DELETE /email/addresses/{email_address_id}
# operationId: Delete Allowed Email Address
export def "delete-allowed-email-address" [
  email_address_id: float
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
    path: "/email/addresses/{email_address_id}"
    path_params: [{name: email_address_id, var: email_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Allowed Email Address
#
# GET /email/addresses/{email_address_id}
# operationId: Get Specific Allowed Email Address
export def "get-specific-allowed-email-address" [
  email_address_id: float
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
    path: "/email/addresses/{email_address_id}"
    path_params: [{name: email_address_id, var: email_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email History
#
# GET /email/history
# operationId: Email History
export def "email-history" [
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
    path: "/email/history"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export History
#
# GET /email/history/export?filename={filename}
# operationId: Export History
export def "export-history" [
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
    path: "/email/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Master Email Templates
#
# GET /email/master-templates
# operationId: Get All Master Email Templates
export def "get-all-master-email-templates" [
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
    path: "/email/master-templates"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Master Template Categories
#
# GET /email/master-templates-categories
# operationId: Get All Master Template Categories
export def "get-all-master-template-categories" [
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
    path: "/email/master-templates-categories"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Email Template Category
#
# GET /email/master-templates-categories/{category_id}
# operationId: Get Specific Email Template Category
export def "get-specific-email-template-category" [
  category_id: string
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
    path: "/email/master-templates-categories/{category_id}"
    path_params: [{name: category_id, var: category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Templates For Category
#
# GET /email/master-templates-categories/{category_id}/master-templates
# operationId: Get All Templates For Category
export def "get-all-templates-for-category" [
  category_id: string
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
    path: "/email/master-templates-categories/{category_id}/master-templates"
    path_params: [{name: category_id, var: category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Master Template
#
# GET /email/master-templates/{template_id}
# operationId: Get Specific Master Template
export def "get-specific-master-template" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/email/master-templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email Price
#
# POST /email/price
# operationId: Email Price
export def "email-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attachments: list # The attachments of the email. See sample request for more details.
  --bcc: list # The bcc of the email. See sample request for more details.
  body: string # The content of the email.
  --cc: list # The cc of the email. See sample request for more details.
  from_email_address_id: float # The sender's email address id.
  --from-name: string # The sender's name.
  subject: string # The subject of the email.
  to: list # The recipients of the email. See sample request for more details.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/price"
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: bcc, var: bcc}, {name: body, var: body}, {name: cc, var: cc}, {name: "from.email_address_id", var: from_email_address_id}, {name: "from.name", var: from_name}, {name: subject, var: subject}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attachments: $attachments, bcc: $bcc, body: $body, cc: $cc, from_email_address_id: $from_email_address_id, from_name: $from_name, subject: $subject, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Test Delivery Receipt
#
# POST /email/receipts
export def "post-email-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # Your URL if using the push option or 'poll' if using the pull option.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email Send
#
# POST /email/send
# operationId: Email Send
export def "email-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: list # The attachments of the email.
  --bcc: list # The bcc of the email. Follows the same structure as `to`.
  body: string # The content of the email.
  --cc: list # The cc of the email. Follows the same structure as `to`.
  from_email_address_id: float # The sender's email address ID.
  --from-name: string # The sender's name.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  to: list # The recipients of the email.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/send"
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: bcc, var: bcc}, {name: body, var: body}, {name: cc, var: cc}, {name: "from.email_address_id", var: from_email_address_id}, {name: "from.name", var: from_name}, {name: schedule, var: schedule}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attachments: $attachments, bcc: $bcc, body: $body, cc: $cc, from_email_address_id: $from_email_address_id, from_name: $from_name, schedule: $schedule, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Email Templates
#
# GET /email/templates
# operationId: Get All Email Templates
export def "get-all-email-templates" [
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
    path: "/email/templates"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create New Email Template from Master Template
#
# POST /email/templates
# operationId: Create New Email Template from Master Template
export def "create-new-email-template-from-master-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  template_id_master: float # The ID of the master template you want to base on.
  template_name: string # The intended name for the new template.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/templates"
    body: {content_type: "application/json", kind: json, fields: [{name: template_id_master, var: template_id_master}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id_master: $template_id_master, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Image to Specific Template
#
# POST /email/templates-images/{template_id}
# operationId: Upload Image to Specific Template
export def "upload-image-to-specific-template" [
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
  --image: string # Uploads your selected image file.
  --url: string # Uploads the image from the supplied URL.
]: any -> any {
  $in | http-request {
    method: post
    path: "/email/templates-images/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, image: $image, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Email Template
#
# DELETE /email/templates/{template_id}
# operationId: Delete Email Template
export def "delete-email-template" [
  template_id: float
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
    path: "/email/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Email Template
#
# GET /email/templates/{template_id}
# operationId: Get Specific Email Template
export def "get-specific-email-template" [
  template_id: float
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
    path: "/email/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Email Template
#
# PUT /email/templates/{template_id}
# operationId: Update an Email Template
export def "update-an-email-template" [
  template_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your template body.
  template_name: string # The intended name for the new template.
]: any -> any {
  $in | http-request {
    method: put
    path: "/email/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, body: $body, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Fax History
#
# GET /fax/history/export?filename={filename}
# operationId: Export Fax History
export def "export-fax-history" [
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
    path: "/fax/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Fax History
#
# GET /fax/history?date_from={date_from}&date_to={date_to}&q={q}&order_by={order_by}
# operationId: Get Fax History
export def "get-fax-history" [
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
    path: "/fax/history"
    fixed_query: "date_from={date_from}&date_to={date_to}&q={q}&order_by={order_by}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price
#
# POST /fax/price
export def "post-fax-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  file_url: string # Your URL to your PDF file.
  --from: string # Your sender id. Must be a valid fax number.
  --from-email: string # An email address where the reply should be emailed to.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  messages: list # Your messages.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/fax/price"
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: custom_string, var: custom_string}, {name: file_url, var: file_url}, {name: from, var: from}, {name: from_email, var: from_email}, {name: list_id, var: list_id}, {name: messages, var: messages}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country, custom_string: $custom_string, file_url: $file_url, from: $from, from_email: $from_email, list_id: $list_id, messages: $messages, schedule: $schedule, source: $source, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Fax Delivery Receipts
#
# GET /fax/receipts
# operationId: List of Fax Delivery Receipts
export def "list-of-fax-delivery-receipts" [
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
    path: "/fax/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Test Delivery Receipt
#
# POST /fax/receipts
# operationId: Add a Test Delivery Receipt
export def "add-a-test-delivery-receipt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # Your URL if using the push option or 'poll' if using the pull option.
]: any -> any {
  $in | http-request {
    method: post
    path: "/fax/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark Fax Delivery Receipts as read
#
# PUT /fax/receipts-read
# operationId: Mark Fax Delivery Receipts as read
export def "mark-fax-delivery-receipts-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-before: float # An optional [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp) - mark all as read before this timestamp. If not given, all receipts will be marked as read.
]: any -> any {
  $in | http-request {
    method: put
    path: "/fax/receipts-read"
    body: {content_type: "application/json", kind: json, fields: [{name: date_before, var: date_before}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    date_before: $date_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Specific Fax Delivery Receipt
#
# GET /fax/receipts/{message_id}
# operationId: Get a Specific Fax Delivery Receipt
export def "get-a-specific-fax-delivery-receipt" [
  message_id: string
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
    path: "/fax/receipts/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Fax
#
# POST /fax/send
# operationId: Send Fax
export def "send-fax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  file_url: string # Your URL to your PDF file.
  --from: string # Your sender id. Must be a valid fax number.
  --from-email: string # An email address where the reply should be emailed to.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  messages: list # Your messages.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/fax/send"
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: custom_string, var: custom_string}, {name: file_url, var: file_url}, {name: from, var: from}, {name: from_email, var: from_email}, {name: list_id, var: list_id}, {name: messages, var: messages}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country, custom_string: $custom_string, file_url: $file_url, from: $from, from_email: $from_email, list_id: $list_id, messages: $messages, schedule: $schedule, source: $source, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forgot Password
#
# PUT /forgot-password
# operationId: Forgot Password
export def "forgot-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: put
    path: "/forgot-password"
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Forgot Password
#
# PUT /forgot-password/verify
# operationId: Verify Forgot Password
export def "verify-forgot-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  activation_token: string # Your email activation token.
  password: string # Your new password.
  subaccount_id: float # Your subaccount id.
]: any -> any {
  $in | http-request {
    method: put
    path: "/forgot-password/verify"
    body: {content_type: "application/json", kind: json, fields: [{name: activation_token, var: activation_token}, {name: password, var: password}, {name: subaccount_id, var: subaccount_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    activation_token: $activation_token, password: $password, subaccount_id: $subaccount_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forgot Username
#
# PUT /forgot-username
# operationId: Forgot Username
export def "forgot-username" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Your country. Used to format phone number. This is required if phone_number is not in international-format.
  --email: string # Your email. This is required if phone_number is not present.
  --phone-number: float # Your phone number. This is required if email is not present.
]: any -> any {
  $in | http-request {
    method: put
    path: "/forgot-username"
    body: {content_type: "application/json", kind: json, fields: [{name: country, var: country}, {name: email, var: email}, {name: phone_number, var: phone_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country, email: $email, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Contact Lists
#
# GET /lists
# operationId: Get all Contact Lists
export def "get-all-contact-lists" [
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
    path: "/lists"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contact list
#
# POST /lists
# operationId: Create a new contact list
export def "create-a-new-contact-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  list_name: string # Your contact list name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists"
    body: {content_type: "application/json", kind: json, fields: [{name: list_name, var: list_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_name: $list_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer a Contact
#
# PUT /lists/{from_list_id}/contacts/{contact_id}/{to_list_id}
# operationId: Transfer a Contact
export def "transfer-a-contact" [
  from_list_id: float
  contact_id: float
  to_list_id: float
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
    method: put
    path: "/lists/{from_list_id}/contacts/{contact_id}/{to_list_id}"
    path_params: [{name: from_list_id, var: from_list_id}, {name: contact_id, var: contact_id}, {name: to_list_id, var: to_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    from_list_id: $from_list_id, contact_id: $contact_id, to_list_id: $to_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific contact list
#
# DELETE /lists/{list_id}
# operationId: Delete a specific contact list
export def "delete-a-specific-contact-list" [
  list_id: float
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
    path: "/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific contact list
#
# GET /lists/{list_id}
# operationId: Get a specific contact list
export def "get-a-specific-contact-list" [
  list_id: float
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
    path: "/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific contact list
#
# PUT /lists/{list_id}
# operationId: Update a specific contact list
export def "update-a-specific-contact-list" [
  list_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --list-name: string # Your new contact list name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: list_name, var: list_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, list_name: $list_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Contacts in a List
#
# GET /lists/{list_id}/contacts
# operationId: Get all Contacts in a List
export def "get-all-contacts-in-a-list" [
  list_id: float
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
    path: "/lists/{list_id}/contacts"
    path_params: [{name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contact
#
# POST /lists/{list_id}/contacts
# operationId: Create a new contact
export def "create-a-new-contact" [
  list_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-city: string # Contact city.
  --address-country: string # Contact two-letter country code defined in ISO 3166.
  --address-line-1: string # Contact address line 1.
  --address-line-2: string # Contact address line 2.
  --address-postal-code: string # Contact postal code.
  --address-state: string # Contact state.
  --custom-1: string # Contact custom 1 text.
  --custom-2: string # Contact custom 2 text.
  --custom-3: string # Contact custom 3 text.
  --custom-4: string # Contact custom 4 text.
  --email: string # Contact email.
  --fax-number: string # Contact fax number.
  --first-name: string # Contact firstname.
  --last-name: string # Contact lastname.
  --organization-name: string # Your organization name.
  phone_number: string # Contact phone number in E.164 format.
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists/{list_id}/contacts"
    path_params: [{name: list_id, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line_1, var: address_line_1}, {name: address_line_2, var: address_line_2}, {name: address_postal_code, var: address_postal_code}, {name: address_state, var: address_state}, {name: custom_1, var: custom_1}, {name: custom_2, var: custom_2}, {name: custom_3, var: custom_3}, {name: custom_4, var: custom_4}, {name: email, var: email}, {name: fax_number, var: fax_number}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: organization_name, var: organization_name}, {name: phone_number, var: phone_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, address_city: $address_city, address_country: $address_country, address_line_1: $address_line_1, address_line_2: $address_line_2, address_postal_code: $address_postal_code, address_state: $address_state, custom_1: $custom_1, custom_2: $custom_2, custom_3: $custom_3, custom_4: $custom_4, email: $email, fax_number: $fax_number, first_name: $first_name, last_name: $last_name, organization_name: $organization_name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific contact
#
# DELETE /lists/{list_id}/contacts/{contact_id}
# operationId: Delete a specific contact
export def "delete-a-specific-contact" [
  list_id: float
  contact_id: float
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
    path: "/lists/{list_id}/contacts/{contact_id}"
    path_params: [{name: list_id, var: list_id}, {name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific contact
#
# GET /lists/{list_id}/contacts/{contact_id}
# operationId: Get a specific contact
export def "get-a-specific-contact" [
  list_id: float
  contact_id: float
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
    path: "/lists/{list_id}/contacts/{contact_id}"
    path_params: [{name: list_id, var: list_id}, {name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific contact
#
# PUT /lists/{list_id}/contacts/{contact_id}
# operationId: Update a specific contact
export def "update-a-specific-contact" [
  list_id: float
  contact_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-city: string # Contact city.
  --address-country: string # Contact two-letter country code defined in ISO 3166.
  --address-line-1: string # Contact address line 1.
  --address-line-2: string # Contact address line 2.
  --address-postal-code: string # Contact postal code.
  --address-state: string # Contact state.
  --custom-1: string # Contact custom 1 text.
  --custom-2: string # Contact custom 2 text.
  --custom-3: string # Contact custom 3 text.
  --custom-4: string # Contact custom 4 text.
  --email: string # Contact email.
  --fax-number: string # Contact fax number.
  --first-name: string # Contact firstname.
  --last-name: string # Contact lastname.
  --organization-name: string # Contact organization name.
  --phone-number: string # Contact phone number in E.164 format.
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{list_id}/contacts/{contact_id}"
    path_params: [{name: list_id, var: list_id}, {name: contact_id, var: contact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line_1, var: address_line_1}, {name: address_line_2, var: address_line_2}, {name: address_postal_code, var: address_postal_code}, {name: address_state, var: address_state}, {name: custom_1, var: custom_1}, {name: custom_2, var: custom_2}, {name: custom_3, var: custom_3}, {name: custom_4, var: custom_4}, {name: email, var: email}, {name: fax_number, var: fax_number}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: organization_name, var: organization_name}, {name: phone_number, var: phone_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, contact_id: $contact_id, address_city: $address_city, address_country: $address_country, address_line_1: $address_line_1, address_line_2: $address_line_2, address_postal_code: $address_postal_code, address_state: $address_state, custom_1: $custom_1, custom_2: $custom_2, custom_3: $custom_3, custom_4: $custom_4, email: $email, fax_number: $fax_number, first_name: $first_name, last_name: $last_name, organization_name: $organization_name, phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Contacts List
#
# GET /lists/{list_id}/export?filename={filename}
# operationId: Export Contacts List
export def "export-contacts-list" [
  list_id: string
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
    path: "/lists/{list_id}/export"
    fixed_query: "filename={filename}"
    path_params: [{name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import Contacts to List
#
# POST /lists/{list_id}/import
# operationId: Import Contacts to List
export def "import-contacts-to-list" [
  list_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  field_order: list # Your field order for your contact import file.
  file_url: string # Path to your CSV import file.
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists/{list_id}/import"
    path_params: [{name: list_id, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: field_order, var: field_order}, {name: file_url, var: file_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, field_order: $field_order, file_url: $file_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show CSV Import File Preview
#
# POST /lists/{list_id}/import-csv-preview
# operationId: Show CSV Import File Preview
export def "show-csv-import-file-preview" [
  list_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_url: string # Path to your CSV import file.
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists/{list_id}/import-csv-preview"
    path_params: [{name: list_id, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file_url, var: file_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, file_url: $file_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Acceptable Import Fields
#
# GET /lists/{list_id}/import-fields
# operationId: Get List of Acceptable Import Fields
export def "get-list-of-acceptable-import-fields" [
  list_id: string
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
    path: "/lists/{list_id}/import-fields"
    path_params: [{name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Duplicate Contacts
#
# PUT /lists/{list_id}/remove-duplicates
# operationId: Remove Duplicate Contacts
export def "remove-duplicate-contacts" [
  list_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  fields: list # List of Contact's fields to be used for checking.
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{list_id}/remove-duplicates"
    path_params: [{name: list_id, var: list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Opted Out Contacts
#
# PUT /lists/{list_id}/remove-opted-out-contacts/{opt_out_list_id}
# operationId: Remove Opted Out Contacts
export def "remove-opted-out-contacts" [
  list_id: float
  opt_out_list_id: float
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
    method: put
    path: "/lists/{list_id}/remove-opted-out-contacts/{opt_out_list_id}"
    path_params: [{name: list_id, var: list_id}, {name: opt_out_list_id, var: opt_out_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    list_id: $list_id, opt_out_list_id: $opt_out_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel All MMS
#
# PUT /mms/cancel-all
# operationId: Cancel All MMS
export def "cancel-all-mms" [
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
    method: put
    path: "/mms/cancel-all"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export MMS History
#
# GET /mms/history/export?filename={filename}
# operationId: Export MMS History
export def "export-mms-history" [
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
    path: "/mms/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MMS History
#
# GET /mms/history?q={q}&order_by={order_by}&date_from={date_from}&date_to={date_to}
# operationId: Get MMS History
export def "get-mms-history" [
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
    path: "/mms/history"
    fixed_query: "q={q}&order_by={order_by}&date_from={date_from}&date_to={date_to}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Price
#
# POST /mms/price
# operationId: Get Price
export def "get-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  --from-email: string # An email address where the reply should be emailed to. If omitted, the reply will be emailed back to the user who sent the outgoing SMS.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  media_file: string # Media file you want to send.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  subject: string # Subject line. Maximum 20 characters.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/mms/price"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: from, var: from}, {name: from_email, var: from_email}, {name: list_id, var: list_id}, {name: media_file, var: media_file}, {name: schedule, var: schedule}, {name: source, var: source}, {name: subject, var: subject}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, from: $from, from_email: $from_email, list_id: $list_id, media_file: $media_file, schedule: $schedule, source: $source, subject: $subject, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Delivery Receipts
#
# GET /mms/receipts
# operationId: Get all Delivery Receipts
export def "get-all-delivery-receipts" [
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
    path: "/mms/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark Receipts As Read
#
# PUT /mms/receipts-read
# operationId: Mark Receipts As Read
export def "mark-receipts-as-read" [
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
    method: put
    path: "/mms/receipts-read"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Delivery Receipt
#
# GET /mms/receipts/{message_id}
# operationId: Get Delivery Receipt
export def "get-delivery-receipt" [
  message_id: string
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
    path: "/mms/receipts/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send MMS
#
# POST /mms/send
# operationId: Send MMS
export def "send-mms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --from: string # The number to send from. Either leave blank or use a ClickSend number only.
  --from-email: string # An email address where the reply should be emailed to. If omitted, the reply will be emailed back to the user who sent the outgoing SMS.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  media_file: string # Media file you want to send.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  subject: string # Subject line. Maximum 20 characters.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/mms/send"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: from, var: from}, {name: from_email, var: from_email}, {name: list_id, var: list_id}, {name: media_file, var: media_file}, {name: schedule, var: schedule}, {name: source, var: source}, {name: subject, var: subject}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, from: $from, from_email: $from_email, list_id: $list_id, media_file: $media_file, schedule: $schedule, source: $source, subject: $subject, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel MMS
#
# PUT /mms/{message_id}/cancel
# operationId: Cancel MMS
export def "cancel-mms" [
  message_id: string
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
    method: put
    path: "/mms/{message_id}/cancel"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Dedicated Numbers
#
# GET /numbers
# operationId: Get all Dedicated Numbers
export def "get-all-dedicated-numbers" [
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
    path: "/numbers"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Buy dedicated number
#
# POST /numbers/buy/{dedicated_number}
# operationId: Buy dedicated number
export def "buy-dedicated-number" [
  dedicated_number: string
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
    path: "/numbers/buy/{dedicated_number}"
    path_params: [{name: dedicated_number, var: dedicated_number}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    dedicated_number: $dedicated_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Dedicated Numbers by Country
#
# GET /numbers/search/{country}?{search}=1&{search_type}=2
# operationId: Search Dedicated Numbers by Country
export def "search-dedicated-numbers-by-country" [
  country: string
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
    path: "/numbers/search/{country}"
    fixed_query: "{search}=1&{search_type}=2"
    path_params: [{name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Direct Mail Campaigns
#
# GET /post/direct-mail/campaigns
# operationId: List Direct Mail Campaigns
export def "list-direct-mail-campaigns" [
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
    path: "/post/direct-mail/campaigns"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Direct Mail Campaign Price
#
# POST /post/direct-mail/campaigns/price
# operationId: Calculate Direct Mail Campaign Price
export def "calculate-direct-mail-campaign-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --areas: list # List of location where you want to send your campaign, and the quantity per location.
  file_urls: list # Campaign file urls. You can submit max 2 file urls.
  name: string # Campaign name.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  size: string # Campaign file size. It can be A5 or DL.
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/direct-mail/campaigns/price"
    body: {content_type: "application/json", kind: json, fields: [{name: areas, var: areas}, {name: file_urls, var: file_urls}, {name: name, var: name}, {name: schedule, var: schedule}, {name: size, var: size}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    areas: $areas, file_urls: $file_urls, name: $name, schedule: $schedule, size: $size, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create New Campaign
#
# POST /post/direct-mail/campaigns/send
# operationId: Create New Campaign
export def "create-new-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --areas: list # List of location where you want to send your campaign, and the quantity per location.
  file_urls: list # Campaign file urls. You can submit max 2 file urls.
  name: string # Campaign name.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  size: string # Campaign file size. It can be A5 or DL.
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/direct-mail/campaigns/send"
    body: {content_type: "application/json", kind: json, fields: [{name: areas, var: areas}, {name: file_urls, var: file_urls}, {name: name, var: name}, {name: schedule, var: schedule}, {name: size, var: size}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    areas: $areas, file_urls: $file_urls, name: $name, schedule: $schedule, size: $size, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Locations
#
# GET /post/direct-mail/locations/search/{country}/?q={query}
# operationId: Search Locations
export def "search-locations" [
  country: string
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
    path: "/post/direct-mail/locations/search/{country}/"
    fixed_query: "q={query}"
    path_params: [{name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detect Address
#
# POST /post/letters/detect-address
# operationId: Detect Address
export def "detect-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Your file contents encoded in `base64`.
  --address: string # Your file contents encoded in `base64`.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/letters/detect-address"
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: address, var: address}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    content: $content, address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Post Letter History
#
# GET /post/letters/history
# operationId: Get Post Letter History
export def "get-post-letter-history" [
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
    path: "/post/letters/history"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Post Letter History
#
# GET /post/letters/history/export?filename={filename}
# operationId: Export Post Letter History
export def "export-post-letter-history" [
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
    path: "/post/letters/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price
#
# POST /post/letters/price
export def "post-post-letters-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: float # Is it in colored?
  --duplex: float # Is it in duplex?
  file_url: string # Your URL to your PDF file.
  --priority-post: float # Is it priority? 0 = Not Priority, 1 = Priority.
  --recipients: list # Your recipients.
  --template-used: float # Whether you used our template or not ([More Info](http://help.clicksend.com/13996-Post/post-letter-template)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/letters/price"
    body: {content_type: "application/json", kind: json, fields: [{name: colour, var: colour}, {name: duplex, var: duplex}, {name: file_url, var: file_url}, {name: priority_post, var: priority_post}, {name: recipients, var: recipients}, {name: template_used, var: template_used}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    colour: $colour, duplex: $duplex, file_url: $file_url, priority_post: $priority_post, recipients: $recipients, template_used: $template_used
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Post Letter
#
# POST /post/letters/send
# operationId: Send Post Letter
export def "send-post-letter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: float # Is it in colour? 0 = Black and White, 1 = Colour.
  --duplex: float # Is it in duplex? 0 = Simplex, 1 = Duplex.
  file_url: string # Your URL to your PDF file.
  --priority-post: float # Is it priority? 0 = Not Priority, 1 = Priority.
  --recipients: list # Your recipients.
  --template-used: float # Whether you used our template or not ([More Info](http://help.clicksend.com/13996-Post/post-letter-template)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/letters/send"
    body: {content_type: "application/json", kind: json, fields: [{name: colour, var: colour}, {name: duplex, var: duplex}, {name: file_url, var: file_url}, {name: priority_post, var: priority_post}, {name: recipients, var: recipients}, {name: template_used, var: template_used}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    colour: $colour, duplex: $duplex, file_url: $file_url, priority_post: $priority_post, recipients: $recipients, template_used: $template_used
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Postcard History
#
# GET /post/postcards/export?filename={filename}
# operationId: Export Postcard History
export def "export-postcard-history" [
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
    path: "/post/postcards/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Postcard History
#
# GET /post/postcards/history
# operationId: Get Postcard History
export def "get-postcard-history" [
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
    path: "/post/postcards/history"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Pricing
#
# POST /post/postcards/price
# operationId: Calculate Pricing
export def "calculate-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_urls: list # Postcard file urls. You can submit max 2 file urls.
  recipients: list # Your recipients.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/postcards/price"
    body: {content_type: "application/json", kind: json, fields: [{name: file_urls, var: file_urls}, {name: recipients, var: recipients}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    file_urls: $file_urls, recipients: $recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send Postcard
#
# POST /post/postcards/send
# operationId: Send Postcard
export def "send-postcard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_urls: list # Postcard file urls. You can submit max 2 file urls.
  recipients: list # Your recipients.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/postcards/send"
    body: {content_type: "application/json", kind: json, fields: [{name: file_urls, var: file_urls}, {name: recipients, var: recipients}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    file_urls: $file_urls, recipients: $recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Post Return Addresses
#
# GET /post/return-addresses
# operationId: Get List of Post Return Addresses
export def "get-list-of-post-return-addresses" [
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
    path: "/post/return-addresses"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Post Return Address
#
# POST /post/return-addresses
# operationId: Create a Post Return Address
export def "create-a-post-return-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_city: string # Your address city.
  address_country: string # Two-letter country code defined in ISO 3166.
  address_line_1: string # Your address line 1.
  --address-line-2: string # Your address line 2.
  address_name: string # Your address name.
  address_postal_code: float # Your address postal code.
  address_state: string # Your address state.
]: any -> any {
  $in | http-request {
    method: post
    path: "/post/return-addresses"
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line_1, var: address_line_1}, {name: address_line_2, var: address_line_2}, {name: address_name, var: address_name}, {name: address_postal_code, var: address_postal_code}, {name: address_state, var: address_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    address_city: $address_city, address_country: $address_country, address_line_1: $address_line_1, address_line_2: $address_line_2, address_name: $address_name, address_postal_code: $address_postal_code, address_state: $address_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Post Return Address
#
# DELETE /post/return-addresses/{return_address_id}
# operationId: Delete Post Return Address
export def "delete-post-return-address" [
  return_address_id: float
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
    path: "/post/return-addresses/{return_address_id}"
    path_params: [{name: return_address_id, var: return_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    return_address_id: $return_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Post Return Address
#
# GET /post/return-addresses/{return_address_id}
# operationId: Get Post Return Address
export def "get-post-return-address" [
  return_address_id: float
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
    path: "/post/return-addresses/{return_address_id}"
    path_params: [{name: return_address_id, var: return_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    return_address_id: $return_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Post Return Address
#
# PUT /post/return-addresses/{return_address_id}
# operationId: Update Post Return Address
export def "update-post-return-address" [
  return_address_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_city: string # Your address city.
  address_country: string # Two-letter country code defined in ISO 3166.
  address_line_1: string # Your address line 1.
  --address-line-2: string # Your address line 2.
  address_name: string # Your address name.
  address_postal_code: float # Your address postal code.
  address_state: string # Your address state.
]: any -> any {
  $in | http-request {
    method: put
    path: "/post/return-addresses/{return_address_id}"
    path_params: [{name: return_address_id, var: return_address_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address_city, var: address_city}, {name: address_country, var: address_country}, {name: address_line_1, var: address_line_1}, {name: address_line_2, var: address_line_2}, {name: address_name, var: address_name}, {name: address_postal_code, var: address_postal_code}, {name: address_state, var: address_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    return_address_id: $return_address_id, address_city: $address_city, address_country: $address_country, address_line_1: $address_line_1, address_line_2: $address_line_2, address_name: $address_name, address_postal_code: $address_postal_code, address_state: $address_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Country Pricing
#
# GET /pricing/{country}?currency={currency}
# operationId: Get Country Pricing
export def "get-country-pricing" [
  country: string
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
    path: "/pricing/{country}"
    fixed_query: "currency={currency}"
    path_params: [{name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Credit Card info
#
# GET /recharge/credit-card
# operationId: Get Credit Card info
export def "get-credit-card-info" [
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
    path: "/recharge/credit-card"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Credit Card info
#
# PUT /recharge/credit-card
# operationId: Update Credit Card info
export def "update-credit-card-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_name: string # Your bank's name that issued the credit card.
  cvc: float # Your CVC digits.
  expiry_month: float # Your credit card expiry month.
  --expiry-year: float # Your credit card expiry year.
  name: string # Your name.
  --number: float # Your credit card no.
]: any -> any {
  $in | http-request {
    method: put
    path: "/recharge/credit-card"
    body: {content_type: "application/json", kind: json, fields: [{name: bank_name, var: bank_name}, {name: cvc, var: cvc}, {name: expiry_month, var: expiry_month}, {name: expiry_year, var: expiry_year}, {name: name, var: name}, {name: number, var: number}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bank_name: $bank_name, cvc: $cvc, expiry_month: $expiry_month, expiry_year: $expiry_year, name: $name, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Packages
#
# GET /recharge/packages?country={country}
# operationId: List of Packages
export def "list-of-packages" [
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
    path: "/recharge/packages"
    fixed_query: "country={country}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase a Package
#
# PUT /recharge/purchase/{package_id}
# operationId: Purchase a Package
export def "purchase-a-package" [
  package_id: float
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
    method: put
    path: "/recharge/purchase/{package_id}"
    path_params: [{name: package_id, var: package_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    package_id: $package_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transactions
#
# GET /recharge/transactions
# operationId: Get Transactions
export def "get-transactions" [
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
    path: "/recharge/transactions"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific transaction
#
# GET /recharge/transactions/{transaction_id}
# operationId: Get a specific transaction
export def "get-a-specific-transaction" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/recharge/transactions/{transaction_id}"
    path_params: [{name: transaction_id, var: transaction_id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: basic
  } {
    transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Referral Accounts
#
# GET /referral/accounts
# operationId: Get List of Referral Accounts
export def "get-list-of-referral-accounts" [
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
    path: "/referral/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Reseller Setting
#
# GET /reseller
# operationId: Get Reseller Setting
export def "get-reseller-setting" [
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
    path: "/reseller"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Reseller Setting
#
# PUT /reseller
# operationId: Update Reseller Setting
export def "update-reseller-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  allow_public_signups: float # Allow public signups.
  colour_navigation: string # Colour navigation.
  company_name: string # Company name.
  default_margin: float # Default margin.
  default_margin_numbers: float # Default margin numbers.
  logo_url_dark: string # Logo URL (dark)
  logo_url_light: string # Logo URL (light)
  subdomain: string # Subdomain.
  trial_balance: float # Trial balance.
]: any -> any {
  $in | http-request {
    method: put
    path: "/reseller"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_public_signups, var: allow_public_signups}, {name: colour_navigation, var: colour_navigation}, {name: company_name, var: company_name}, {name: default_margin, var: default_margin}, {name: default_margin_numbers, var: default_margin_numbers}, {name: logo_url_dark, var: logo_url_dark}, {name: logo_url_light, var: logo_url_light}, {name: subdomain, var: subdomain}, {name: trial_balance, var: trial_balance}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    allow_public_signups: $allow_public_signups, colour_navigation: $colour_navigation, company_name: $company_name, default_margin: $default_margin, default_margin_numbers: $default_margin_numbers, logo_url_dark: $logo_url_dark, logo_url_light: $logo_url_light, subdomain: $subdomain, trial_balance: $trial_balance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Reseller Accounts
#
# GET /reseller/accounts
# operationId: List of Reseller Accounts
export def "list-of-reseller-accounts" [
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
    path: "/reseller/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Reseller Account
#
# POST /reseller/accounts
# operationId: Create Reseller Account
export def "create-reseller-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # Your delivery to value.
  country: string # Client country.
  password: string # Your password.
  user_email: string # Your email.
  user_first_name: string # Your first name.
  user_last_name: string # Your last name.
  user_phone: string # Your phone number in E.164 format.
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: post
    path: "/reseller/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: country, var: country}, {name: password, var: password}, {name: user_email, var: user_email}, {name: user_first_name, var: user_first_name}, {name: user_last_name, var: user_last_name}, {name: user_phone, var: user_phone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_name: $account_name, country: $country, password: $password, user_email: $user_email, user_first_name: $user_first_name, user_last_name: $user_last_name, user_phone: $user_phone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Reseller Account - Public
#
# POST /reseller/accounts-public
# operationId: Create Reseller Account - Public
export def "create-reseller-account-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # Your delivery to value.
  country: string # Client country.
  password: string # Your password.
  reseller_user_id: float # Reseller User ID.
  user_email: string # Your email.
  user_first_name: string # Your first name.
  user_last_name: string # Your last name.
  user_phone: string # Your phone number in E.164 format.
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: post
    path: "/reseller/accounts-public"
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: country, var: country}, {name: password, var: password}, {name: reseller_user_id, var: reseller_user_id}, {name: user_email, var: user_email}, {name: user_first_name, var: user_first_name}, {name: user_last_name, var: user_last_name}, {name: user_phone, var: user_phone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_name: $account_name, country: $country, password: $password, reseller_user_id: $reseller_user_id, user_email: $user_email, user_first_name: $user_first_name, user_last_name: $user_last_name, user_phone: $user_phone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Reseller Account
#
# GET /reseller/accounts/{client_user_id}
# operationId: Get Reseller Account
export def "get-reseller-account" [
  client_user_id: float
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
    path: "/reseller/accounts/{client_user_id}"
    path_params: [{name: client_user_id, var: client_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    client_user_id: $client_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Reseller Account
#
# PUT /reseller/accounts/{client_user_id}
# operationId: Update Reseller Account
export def "update-reseller-account" [
  client_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # Your delivery to value.
  country: string # Client country.
  password: string # Your password.
  user_email: string # Your email.
  user_first_name: string # Your first name.
  user_last_name: string # Your last name.
  user_phone: string # Your phone number in E.164 format.
  username: string # Your username.
]: any -> any {
  $in | http-request {
    method: put
    path: "/reseller/accounts/{client_user_id}"
    path_params: [{name: client_user_id, var: client_user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: country, var: country}, {name: password, var: password}, {name: user_email, var: user_email}, {name: user_first_name, var: user_first_name}, {name: user_last_name, var: user_last_name}, {name: user_phone, var: user_phone}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    client_user_id: $client_user_id, account_name: $account_name, country: $country, password: $password, user_email: $user_email, user_first_name: $user_first_name, user_last_name: $user_last_name, user_phone: $user_phone, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer Credit
#
# PUT /reseller/transfer-credit
# operationId: Transfer Credit
export def "transfer-credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  balance: float # Your amount.
  client_user_id: string # Your client user id.
  currency: string # Your currency.
]: any -> any {
  $in | http-request {
    method: put
    path: "/reseller/transfer-credit"
    body: {content_type: "application/json", kind: json, fields: [{name: balance, var: balance}, {name: client_user_id, var: client_user_id}, {name: currency, var: currency}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    balance: $balance, client_user_id: $client_user_id, currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reseller By Subdomain
#
# GET /reseller/{subdomain}
# operationId: Reseller By Subdomain
export def "reseller-by-subdomain" [
  subdomain: string
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
    path: "/reseller/{subdomain}"
    path_params: [{name: subdomain, var: subdomain}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    subdomain: $subdomain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SDK Download
#
# GET /sdk-download/{type}
# operationId: SDK Download
export def "sdk-download" [
  type: string
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
    path: "/sdk-download/{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Contacts-Lists
#
# GET /search/contacts-lists?q={q}
# operationId: Search Contacts-Lists
export def "search-contacts-lists" [
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
    path: "/search/contacts-lists"
    fixed_query: "q={q}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of SMS Campaigns
#
# GET /sms-campaigns
# operationId: Get list of SMS Campaigns
export def "get-list-of-sms-campaigns" [
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
    path: "/sms-campaigns"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price for SMS Campaign
#
# POST /sms-campaigns/price
# operationId: Calculate Price for SMS Campaign
export def "calculate-price-for-sms-campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your campaign message.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  list_id: float # Your list id.
  name: string # Your campaign name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms-campaigns/price"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: from, var: from}, {name: list_id, var: list_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, from: $from, list_id: $list_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use Short URL
#
# POST /sms-campaigns/send
# operationId: Use Short URL
export def "use-short-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your campaign message.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  list_id: float # Your list id.
  name: string # Your campaign name.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  url_to_shorten: string # The URL you want to shorten (only required when using this feature). This must be only `http` or `https`.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms-campaigns/send"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: from, var: from}, {name: list_id, var: list_id}, {name: name, var: name}, {name: schedule, var: schedule}, {name: url_to_shorten, var: url_to_shorten}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, from: $from, list_id: $list_id, name: $name, schedule: $schedule, url_to_shorten: $url_to_shorten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Tracking Export
#
# GET /sms-campaigns/{campaign_id}/link-export?filename={filename}
# operationId: Link Tracking Export
export def "link-tracking-export" [
  campaign_id: float
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
    path: "/sms-campaigns/{campaign_id}/link-export"
    fixed_query: "filename={filename}"
    path_params: [{name: campaign_id, var: campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    campaign_id: $campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Statistics
#
# GET /sms-campaigns/{campaign_id}/link-statistics
# operationId: Link Statistics
export def "link-statistics" [
  campaign_id: float
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
    path: "/sms-campaigns/{campaign_id}/link-statistics"
    path_params: [{name: campaign_id, var: campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    campaign_id: $campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link Tracking
#
# GET /sms-campaigns/{campaign_id}/link-tracking
# operationId: Link Tracking
export def "link-tracking" [
  campaign_id: float
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
    path: "/sms-campaigns/{campaign_id}/link-tracking"
    path_params: [{name: campaign_id, var: campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    campaign_id: $campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SMS Campaign
#
# GET /sms-campaigns/{sms_campaign_id}
# operationId: Get SMS Campaign
export def "get-sms-campaign" [
  sms_campaign_id: float
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
    path: "/sms-campaigns/{sms_campaign_id}"
    path_params: [{name: sms_campaign_id, var: sms_campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    sms_campaign_id: $sms_campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an SMS Campaign
#
# PUT /sms-campaigns/{sms_campaign_id}
# operationId: Update an SMS Campaign
export def "update-an-sms-campaign" [
  sms_campaign_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your campaign message.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  list_id: float # Your list id.
  name: string # Your campaign name.
  --schedule: float # Leave blank for immediate delivery. Will replace existing schedule (even if left blank). Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms-campaigns/{sms_campaign_id}"
    path_params: [{name: sms_campaign_id, var: sms_campaign_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: from, var: from}, {name: list_id, var: list_id}, {name: name, var: name}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    sms_campaign_id: $sms_campaign_id, body: $body, from: $from, list_id: $list_id, name: $name, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an SMS Campaign
#
# PUT /sms-campaigns/{sms_campaign_id}/cancel
# operationId: Cancel an SMS Campaign
export def "cancel-an-sms-campaign" [
  sms_campaign_id: float
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
    method: put
    path: "/sms-campaigns/{sms_campaign_id}/cancel"
    path_params: [{name: sms_campaign_id, var: sms_campaign_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    sms_campaign_id: $sms_campaign_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel all Scheduled Messages
#
# PUT /sms/cancel-all
# operationId: Cancel all Scheduled Messages
export def "cancel-all-scheduled-messages" [
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
    method: put
    path: "/sms/cancel-all"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Email-to-SMS Allowed Address
#
# GET /sms/email-sms
# operationId: List of Email-to-SMS Allowed Address
export def "list-of-email-to-sms-allowed-address" [
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
    path: "/sms/email-sms"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Email to SMS Allowed Address
#
# POST /sms/email-sms
# operationId: Create Email to SMS Allowed Address
export def "create-email-to-sms-allowed-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # Your email address.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/email-sms"
    body: {content_type: "application/json", kind: json, fields: [{name: email_address, var: email_address}, {name: from, var: from}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address: $email_address, from: $from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Stripped Strings
#
# GET /sms/email-sms-stripped-strings
# operationId: List Stripped Strings
export def "list-stripped-strings" [
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
    path: "/sms/email-sms-stripped-strings"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Stripped String
#
# POST /sms/email-sms-stripped-strings
# operationId: Create Stripped String
export def "create-stripped-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  strip_string: string # The string that you want to strip from the body of email.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/email-sms-stripped-strings"
    body: {content_type: "application/json", kind: json, fields: [{name: strip_string, var: strip_string}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    strip_string: $strip_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Stripped String
#
# DELETE /sms/email-sms-stripped-strings/{rule_id}
# operationId: Delete Stripped String
export def "delete-stripped-string" [
  rule_id: float
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
    path: "/sms/email-sms-stripped-strings/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find Specific Stripped String
#
# GET /sms/email-sms-stripped-strings/{rule_id}
# operationId: Find Specific Stripped String
export def "find-specific-stripped-string" [
  rule_id: float
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
    path: "/sms/email-sms-stripped-strings/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Stripped String
#
# PUT /sms/email-sms-stripped-strings/{rule_id}
# operationId: Update Stripped String
export def "update-stripped-string" [
  rule_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strip-string: string # The string that you want to strip from the body of email.
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms/email-sms-stripped-strings/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: strip_string, var: strip_string}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    rule_id: $rule_id, strip_string: $strip_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Email-to-SMS Allowed Address
#
# DELETE /sms/email-sms/{email_address_id}
# operationId: Delete Email-to-SMS Allowed Address
export def "delete-email-to-sms-allowed-address" [
  email_address_id: float
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
    path: "/sms/email-sms/{email_address_id}"
    path_params: [{name: email_address_id, var: email_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific Email-to-SMS Allowed Address
#
# GET /sms/email-sms/{email_address_id}
# operationId: Get specific Email-to-SMS Allowed Address
export def "get-specific-email-to-sms-allowed-address" [
  email_address_id: float
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
    path: "/sms/email-sms/{email_address_id}"
    path_params: [{name: email_address_id, var: email_address_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Email-to-SMS Allowed Address
#
# PUT /sms/email-sms/{email_address_id}
# operationId: Update Email-to-SMS Allowed Address
export def "update-email-to-sms-allowed-address" [
  email_address_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # Your email address.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms/email-sms/{email_address_id}"
    path_params: [{name: email_address_id, var: email_address_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_address, var: email_address}, {name: from, var: from}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email_address_id: $email_address_id, email_address: $email_address, from: $from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export SMS History
#
# GET /sms/history/export?filename={filename}
# operationId: Export SMS History
export def "export-sms-history" [
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
    path: "/sms/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all History
#
# GET /sms/history?date_from={date_from}&date_to={date_to}
# operationId: Get all History
export def "get-all-history" [
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
    path: "/sms/history"
    fixed_query: "date_from={date_from}&date_to={date_to}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Inbound SMS - Pull
#
# GET /sms/inbound
# operationId: Get all Inbound SMS - Pull
export def "get-all-inbound-sms-pull" [
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
    path: "/sms/inbound"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Test Inbound SMS
#
# POST /sms/inbound
# operationId: Add a Test Inbound SMS
export def "add-a-test-inbound-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # Your URL if using the push option or 'poll' if using the pull option.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/inbound"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark all Inbound SMS as read
#
# PUT /sms/inbound-read
# operationId: Mark all Inbound SMS as read
export def "mark-all-inbound-sms-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  date_before: float # An optional timestamp - mark all as read before this timestamp. If not given, all messages will be marked as read.
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms/inbound-read"
    body: {content_type: "application/json", kind: json, fields: [{name: date_before, var: date_before}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    date_before: $date_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a specific Inbound SMS as read
#
# PUT /sms/inbound-read/{message_id}
# operationId: Mark a specific Inbound SMS as read
export def "mark-a-specific-inbound-sms-as-read" [
  message_id: string
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
    method: put
    path: "/sms/inbound-read/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Inbound - Pull
#
# GET /sms/inbound/{outbound_message_id}
# operationId: Get Specific Inbound - Pull
export def "get-specific-inbound-pull" [
  outbound_message_id: string
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
    path: "/sms/inbound/{outbound_message_id}"
    path_params: [{name: outbound_message_id, var: outbound_message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    outbound_message_id: $outbound_message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price
#
# POST /sms/price
export def "post-sms-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/price"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: from, var: from}, {name: list_id, var: list_id}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, from: $from, list_id: $list_id, schedule: $schedule, source: $source, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Delivery Receipts
#
# GET /sms/receipts
export def "get-sms-receipts" [
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
    path: "/sms/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Test Delivery Receipt
#
# POST /sms/receipts
export def "post-sms-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # Your URL if using the push option or 'poll' if using the pull option.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark Delivery Receipts as read
#
# PUT /sms/receipts-read
# operationId: Mark Delivery Receipts as read
export def "mark-delivery-receipts-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-before: float # An optional timestamp - mark all as read before this timestamp. If not given, all receipts will be marked as read.
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms/receipts-read"
    body: {content_type: "application/json", kind: json, fields: [{name: date_before, var: date_before}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    date_before: $date_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Specific Delivery Receipt
#
# GET /sms/receipts/{message_id}
# operationId: Get a Specific Delivery Receipt
export def "get-a-specific-delivery-receipt" [
  message_id: string
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
    path: "/sms/receipts/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an SMS
#
# POST /sms/send
# operationId: Send an SMS
export def "send-an-sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # Recipient country.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --from: string # Your sender id - [more info](http://help.clicksend.com/SMS/what-is-a-sender-id-or-sender-number).
  --from-email: string # An email address where the reply should be emailed to. If omitted, the reply will be emailed back to the user who sent the outgoing SMS.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/send"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: from, var: from}, {name: from_email, var: from_email}, {name: list_id, var: list_id}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, from: $from, from_email: $from_email, list_id: $list_id, schedule: $schedule, source: $source, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Templates
#
# GET /sms/templates
# operationId: List of Templates
export def "list-of-templates" [
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
    path: "/sms/templates"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Template
#
# POST /sms/templates
# operationId: Create a Template
export def "create-a-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your template body.
  template_name: string # Your template name.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sms/templates"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Template
#
# DELETE /sms/templates/{template_id}
# operationId: Delete a Template
export def "delete-a-template" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/sms/templates/{template_id}"
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
# PUT /sms/templates/{template_id}
# operationId: Update a Template
export def "update-a-template" [
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
  body: string # Your template body.
  template_name: string # Your template name.
]: any -> any {
  $in | http-request {
    method: put
    path: "/sms/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: template_name, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    template_id: $template_id, body: $body, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a Scheduled Message
#
# PUT /sms/{message_id}/cancel
# operationId: Cancel a Scheduled Message
export def "cancel-a-scheduled-message" [
  message_id: string
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
    method: put
    path: "/sms/{message_id}/cancel"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SMS Statistics
#
# GET /statistics/sms
# operationId: Get SMS Statistics
export def "get-sms-statistics" [
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
    path: "/statistics/sms"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Voice Statistics
#
# GET /statistics/voice
# operationId: Get Voice Statistics
export def "get-voice-statistics" [
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
    path: "/statistics/voice"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Subaccounts
#
# GET /subaccounts
# operationId: Get all Subaccounts
export def "get-all-subaccounts" [
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
    path: "/subaccounts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new subaccount
#
# POST /subaccounts
# operationId: Create a new subaccount
export def "create-a-new-subaccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-billing: float # Your access billing flag value, must be 1 or 0.
  --access-contacts: float # Your access contacts flag value, must be 1 or 0.
  --access-reporting: float # Your access reporting flag value, must be 1 or 0.
  --access-settings: float # Your access settings flag value, must be 1 or 0.
  --access-users: float # Your access users flag value, must be 1 or 0.
  api_username: string # Your new api username.
  email: string # Your new email.
  first_name: string # Your firstname.
  last_name: string # Your lastname.
  password: string # Your new password.
  phone_number: string # Your phone number in E.164 format.
  --share-campaigns: float # Your share campaigns flag value, must be 1 or 0.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subaccounts"
    body: {content_type: "application/json", kind: json, fields: [{name: access_billing, var: access_billing}, {name: access_contacts, var: access_contacts}, {name: access_reporting, var: access_reporting}, {name: access_settings, var: access_settings}, {name: access_users, var: access_users}, {name: api_username, var: api_username}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: password, var: password}, {name: phone_number, var: phone_number}, {name: share_campaigns, var: share_campaigns}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    access_billing: $access_billing, access_contacts: $access_contacts, access_reporting: $access_reporting, access_settings: $access_settings, access_users: $access_users, api_username: $api_username, email: $email, first_name: $first_name, last_name: $last_name, password: $password, phone_number: $phone_number, share_campaigns: $share_campaigns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific subaccount
#
# DELETE /subaccounts/{subaccount_id}
# operationId: Delete a specific subaccount
export def "delete-a-specific-subaccount" [
  subaccount_id: float
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
    path: "/subaccounts/{subaccount_id}"
    path_params: [{name: subaccount_id, var: subaccount_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    subaccount_id: $subaccount_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific subaccount
#
# GET /subaccounts/{subaccount_id}
# operationId: Get a specific subaccount
export def "get-a-specific-subaccount" [
  subaccount_id: string
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
    path: "/subaccounts/{subaccount_id}"
    path_params: [{name: subaccount_id, var: subaccount_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    subaccount_id: $subaccount_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a specific subaccount
#
# PUT /subaccounts/{subaccount_id}
# operationId: Update a specific subaccount
export def "update-a-specific-subaccount" [
  subaccount_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-billing: float # Your access billing flag value, must be 1 or 0.
  --access-contacts: float # Your access contacts flag value, must be 1 or 0.
  --access-reporting: float # Your access reporting flag value, must be 1 or 0.
  --access-settings: float # Your access settings flag value, must be 1 or 0.
  --access-users: float # Your access users flag value, must be 1 or 0.
  --email: string # Your new email.
  --first-name: string # Your firstname.
  --last-name: string # Your lastname.
  --password: string # Your new password.
  --phone-number: string # Your phone number in E.164 format.
  --share-campaigns: float # Your share campaigns flag value, must be 1 or 0.
]: any -> any {
  $in | http-request {
    method: put
    path: "/subaccounts/{subaccount_id}"
    path_params: [{name: subaccount_id, var: subaccount_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access_billing, var: access_billing}, {name: access_contacts, var: access_contacts}, {name: access_reporting, var: access_reporting}, {name: access_settings, var: access_settings}, {name: access_users, var: access_users}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: password, var: password}, {name: phone_number, var: phone_number}, {name: share_campaigns, var: share_campaigns}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    subaccount_id: $subaccount_id, access_billing: $access_billing, access_contacts: $access_contacts, access_reporting: $access_reporting, access_settings: $access_settings, access_users: $access_users, email: $email, first_name: $first_name, last_name: $last_name, password: $password, phone_number: $phone_number, share_campaigns: $share_campaigns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate API Key
#
# PUT /subaccounts/{subaccount_id}/regen-api-key
# operationId: Regenerate API Key
export def "regenerate-api-key" [
  subaccount_id: float
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
    method: put
    path: "/subaccounts/{subaccount_id}/regen-api-key"
    path_params: [{name: subaccount_id, var: subaccount_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    subaccount_id: $subaccount_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Timezones
#
# GET /timezones
# operationId: Get Timezones
export def "get-timezones" [
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
    path: "/timezones"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a file
#
# POST /uploads?convert={convert}
# operationId: Upload a file
export def "upload-a-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # Your file contents encoded in `base64`.
  convert: string # Conversion type: `fax`, `mms`, `csv` or `post`
  --file: string # Your file.
]: any -> any {
  $in | http-request {
    method: post
    path: "/uploads"
    fixed_query: "convert={convert}"
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: convert, var: convert}, {name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    content: $content, convert: $convert, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel all Voice Calls
#
# PUT /voice/cancel-all
# operationId: Cancel all Voice Calls
export def "cancel-all-voice-calls" [
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
    method: put
    path: "/voice/cancel-all"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Voice History
#
# GET /voice/history/export?filename={filename}
# operationId: Export Voice History
export def "export-voice-history" [
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
    path: "/voice/history/export"
    fixed_query: "filename={filename}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Voice History
#
# GET /voice/history?date_from={date_from}&date_to={date_to}
# operationId: Get Voice History
export def "get-voice-history" [
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
    path: "/voice/history"
    fixed_query: "date_from={date_from}&date_to={date_to}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Voice Languages
#
# GET /voice/lang
# operationId: Voice Languages
export def "voice-languages" [
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
    path: "/voice/lang"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Price
#
# POST /voice/price
export def "post-voice-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # The country of the recipient.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --lang: string # au (string, required) - See section on available languages.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'.
  --require-input: float # Whether you want to receive a keypress from the call recipient (1 for on, 0 [default] for off)
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
  voice: string # Either 'female' or 'male'.
]: any -> any {
  $in | http-request {
    method: post
    path: "/voice/price"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: lang, var: lang}, {name: list_id, var: list_id}, {name: require_input, var: require_input}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, lang: $lang, list_id: $list_id, require_input: $require_input, schedule: $schedule, source: $source, to: $to, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Voice receipts
#
# GET /voice/receipts
# operationId: Get Voice receipts
export def "get-voice-receipts" [
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
    path: "/voice/receipts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Test Delivery Receipt
#
# POST /voice/receipts
export def "post-voice-receipts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # Your URL if using the push option or 'poll' if using the pull option.
]: any -> any {
  $in | http-request {
    method: post
    path: "/voice/receipts"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marked Voice Receipts as Read
#
# PUT /voice/receipts-read?date_before={date_before}
# operationId: Marked Voice Receipts as Read
export def "marked-voice-receipts-as-read" [
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
    method: put
    path: "/voice/receipts-read"
    fixed_query: "date_before={date_before}"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Specific Voice Receipt
#
# GET /voice/receipts/{message_id}
# operationId: Get Specific Voice Receipt
export def "get-specific-voice-receipt" [
  message_id: string
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
    path: "/voice/receipts/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a Voice Call
#
# POST /voice/send
# operationId: Send a Voice Call
export def "send-a-voice-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Your message.
  --country: string # The country of the recipient.
  --custom-string: string # Your reference. Will be passed back with all replies and delivery reports.
  --lang: string # au (string, required) - See section on available languages.
  --list-id: float # Your list ID if sending to a whole list. Can be used instead of 'to'. Will override 'to' if both are used.
  --machine-detection: float # Whether to attempt to detect an answering machine or voicemail service and leave a message (1 for on, 0 [default] for off)
  --require-input: float # Whether you want to receive a keypress from the call recipient (1 for on, 0 [default] for off)
  --schedule: float # Leave blank for immediate delivery. Your schedule time as a [unix timestamp](http://help.clicksend.com/what-is-a-unix-timestamp).
  --source: string # Your method of sending e.g. 'wordpress', 'php', 'c#'.
  to: string # Recipient number in E.164 format or local format ([more info](https://help.clicksend.com/SMS/what-format-does-the-recipient-phone-number-need-to-be-in)).
  voice: string # Either 'female' or 'male'.
]: any -> any {
  $in | http-request {
    method: post
    path: "/voice/send"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: country, var: country}, {name: custom_string, var: custom_string}, {name: lang, var: lang}, {name: list_id, var: list_id}, {name: machine_detection, var: machine_detection}, {name: require_input, var: require_input}, {name: schedule, var: schedule}, {name: source, var: source}, {name: to, var: to}, {name: voice, var: voice}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body, country: $country, custom_string: $custom_string, lang: $lang, list_id: $list_id, machine_detection: $machine_detection, require_input: $require_input, schedule: $schedule, source: $source, to: $to, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a Specific Voice Call
#
# PUT /voice/{message_id}/cancel
# operationId: Cancel a Specific Voice Call
export def "cancel-a-specific-voice-call" [
  message_id: string
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
    method: put
    path: "/voice/{message_id}/cancel"
    path_params: [{name: message_id, var: message_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
