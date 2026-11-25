# Auto-generated client for App Center Client v0.1
# Source: https://api.apis.guru/v2/specs/appcenter.ms/v0.1/openapi.json
# Auth: --token flag or $env.APP_CENTER_CLIENT_TOKEN

const CLIENT = {
  base_url: "https://api.appcenter.ms"
  token_env_var: "APP_CENTER_CLIENT_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-token, in: header, header_name: X-API-Token, prefix: ""}
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

def base-url-completer [] { ["https://api.appcenter.ms"] }
def auth-scheme-completer [] { ["x-api-token" "basic" "basic-credentials"] }

# Completers for enum parameters
def order-by-completer [] { ["display_name" "name"] }
def os-completer [] { ["Android" "Custom" "Linux" "Tizen" "Windows" "iOS" "macOS" "tvOS"] }
def platform-completer [] { ["Cordova" "Custom" "Electron" "Java" "Objective-C-Swift" "React-Native" "UWP" "Unity" "WPF" "WinForms" "Xamarin"] }
def inlinecount-completer [] { ["allpages" "none"] }
def service-completer [] { ["Build" "Test"] }
def period-completer [] { ["Current" "Next" "Previous"] }
def trigger-completer [] { ["continous" "continuous" "manual"] }
def format-completer [] { ["json" "yaml"] }
def os-completer-1 [] { ["Android" "Windows" "iOS" "macOS"] }
def platform-completer-1 [] { ["Java" "Objective-C-Swift" "React-Native" "UWP" "Xamarin"] }
def status-completer [] { ["cancelling"] }
def download-type-completer [] { ["build" "bundle" "logs" "mapping" "symbols"] }
def group-type-completer [] { ["GroupType1" "GroupType2"] }
def group-status-completer [] { ["closed" "ignored" "open"] }
def orderby-completer [] { ["count asc" "count desc" "display_id asc" "display_id desc" "impacted_users asc" "impacted_users desc" "last_occurrence asc" "last_occurrence desc"] }
def status-completer-1 [] { ["closed" "ignored" "open"] }
def error-type-completer [] { ["CrashingErrors" "HandledErrors"] }
def track-completer [] { ["alpha" "beta" "production" "testflight-external" "testflight-internal"] }
def type-completer [] { ["apple" "googleplay" "intune"] }
def error-type-completer-1 [] { ["all" "handledError" "unhandledError"] }
def error-type-completer-2 [] { ["handledError" "unhandledError"] }
def order-completer [] { ["asc" "desc"] }
def sort-completer [] { ["exceptionClassName" "exceptionMessage" "exceptionMethod" "lastOccurrence" "matchingReportsCount"] }
def state-completer [] { ["closed" "ignored" "open"] }
def format-completer-1 [] { ["json" "txt"] }
def sort-completer-1 [] { ["deviceName" "errorGroupId" "exceptionClassName" "exceptionFile" "exceptionLine" "exceptionMessage" "exceptionMethod" "osVersion" "timestamp" "userId"] }
def type-completer-1 [] { ["application_insights_instrumentation_key" "application_insights_linked_subscription" "blob_storage_connection_string" "blob_storage_linked_subscription"] }
def role-completer [] { ["admin" "collaborator" "member"] }
def source-host-completer [] { ["bitbucket" "github" "gitlab" "vsts"] }
def form-completer [] { ["full" "lite"] }
def status-completer-2 [] { ["all" "processed" "uploaded"] }
def symbol-type-completer [] { ["AndroidProguard" "Apple" "Breakpad" "JavaScript" "UWP"] }
def status-completer-3 [] { ["aborted" "committed"] }
def file-type-completer [] { ["app-file" "dsym-file" "test-file"] }
def tools-completer [] { ["node" "xamarin" "xcode"] }
def upload-status-completer [] { ["uploadCanceled" "uploadFinished"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    test-gdpr-export-accounts: "record<resources: table<path: string, rel: string>>"
    test-gdpr-export-account: "record<id: string>"
    test-gdpr-export-feature-flag: "record<name: string, target_id: string>"
    organizations-list-administered: "record<organizations: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>>"
    user-api-tokens-list: "table<created_at: string, description: string, id: string, scope: list<string>>"
    user-api-tokens-new: "record<api_token: string, created_at: string, description: string, id: string, scope: list<string>>"
    apps-list: "table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-create: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-get: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-update: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    analytics-device-counts: "record<daily: table<count: int, datetime: string>, monthly: table<count: int, datetime: string>, weekly: table<count: int, datetime: string>>"
    analytics-list-audiences: "record<nextLink: string, values: table<definition: string, description: string, estimated_count: int, name: string, state: string>>"
    analytics-test-audience: "record<custom_properties: record, definition: string, estimated_count: int, estimated_total_count: int>"
    analytics-list-custom-properties: "record<values: record>"
    analytics-list-device-properties: "record<values: record>"
    analytics-list-device-property-values: "record<values: list<string>>"
    analytics-get-audience: "record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string>"
    analytics-audience-name-exists: "record"
    analytics-create-or-update-audience: "record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string>"
    analytics-crash-counts: "record<count: int, crashes: table<count: int, datetime: string>>"
    analytics-crash-groups-totals: "table<app_version: string, crash_group_id: string, overall: record<crash_count: int, device_count: int>>"
    analytics-crash-group-counts: "record<count: int, crashes: table<count: int, datetime: string>>"
    analytics-crash-group-model-counts: "record<crash_count: int, models: table<crash_count: int, model_name: string>>"
    analytics-crash-group-operating-system-counts: "record<crash_count: int, operating_systems: table<crash_count: int, operating_system_name: string>>"
    analytics-crash-group-totals: "record<crash_count: int, device_count: int>"
    analytics-crash-free-device-percentages: "record<average_percentage: float, daily_percentages: table<datetime: string, percentage: float>>"
    analytics-distribution-release-counts: "record<counts: table<distribution_group: string, release_id: string, total_count: int, unique_count: int>, total: int>"
    analytics-events: "record<events: table<count: int, count_per_device: float, count_per_session: float, device_count: int, id: string, name: string, previous_count: int, previous_device_count: int>, total: int, total_devices: int>"
    analytics-event-per-device-count: "record<avg_count_per_device: float, count_per_device: table<count: float, datetime: string>, previous_avg_count_per_device: float>"
    analytics-event-per-session-count: "record<avg_count_per_session: float, count_per_session: table<count: float, datetime: string>, previous_avg_count_per_session: float>"
    analytics-event-device-count: "record<devices_count: table<count: int, datetime: string>, previous_total_devices_with_event: int, total_devices: int, total_devices_with_event: int>"
    analytics-event-count: "record<count: table<count: int, datetime: string>, previous_total_count: int, total_count: int>"
    analytics-event-properties: "record<event_properties: list<string>>"
    analytics-event-property-counts: "record<total: int, values: table<count: int, name: string, previous_count: int>>"
    analytics-generic-log-flow: "record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>"
    analytics-language-counts: "record<languages: table<count: int, language_name: string, previous_count: int>, total: int>"
    analytics-log-flow: "record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, install_id: string, timestamp: string, type: string>>"
    analytics-model-counts: "record<models: table<count: int, model_name: string, previous_count: int>, total: int>"
    analytics-operating-system-counts: "record<oses: table<count: int, os_name: string, previous_count: int>, total: int>"
    analytics-place-counts: "record<places: table<code: string, count: int, previous_count: int>, total: int>"
    analytics-session-counts: "table<count: int, datetime: string>"
    analytics-session-durations-distribution: "record<average_duration: string, distribution: table<bucket: string, count: int>, previous_average_duration: string>"
    analytics-per-device-counts: "record<average_sessions_per_user: float, previous_average_sessions_per_user: float, previous_total_count: int, sessions_per_user: table<count: float, datetime: string>, total_count: int>"
    analytics-versions: "record<total: int, versions: table<count: int, previous_count: int, version: string>>"
    app-api-tokens-list: "table<created_at: string, description: string, id: string, scope: list<string>>"
    app-api-tokens-new: "record<api_token: string, created_at: string, description: string, id: string, scope: list<string>>"
    apple-mapping-get: "record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string>"
    apple-mapping-create: "record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string>"
    apple-mapping-test-flight-groups: "table<appleId: float, id: string, name: string, providerId: float>"
    apps-delete-avatar: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-update-avatar: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    azure-subscription-list-for-app: "table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>"
    billing-aggregated-information-get-by-app: "record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string>"
    builds-list-branches: "table<configured: bool, lastBuild: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>>"
    builds-list-by-branch: "table<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>"
    builds-create: "record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>"
    branch-configurations-delete: "record<message: string>"
    branch-configurations-get: "record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>"
    branch-configurations-create: "record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>"
    branch-configurations-update: "record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>"
    build-configurations-get: "record<yaml: string>"
    builds-list-toolset-projects: "record<android: record<androidModules: list<record>, gradleWrapperPath: string>, buildscripts: any, commit: string, javascript: record<javascriptSolutions: list<record>, packageJsonPaths: list<string>>, testcloud: record<projects: list<record>>, uwp: record<uwpSolutions: list<record>>, xamarin: record<xamarinSolutions: list<record>>, xcode: record<xcodeSchemeContainers: list<record>>>"
    bugtracker-get-settings: "record<event_types: list<string>, settings: record<callback_url: string, owner_name: string, type: string>, state: string, token_id: string, type: string>"
    bug-tracker-get-repo-issue-from-crash: "record<bug_tracker_type: string, event_type: string, id: string, mobile_center_id: string, repo_name: string, title: string, url: string>"
    builds-get-status-by-app-id: "record<message: string, os: string, service: string, status: string, url: string, valid_until: int>"
    builds-get: "record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>"
    builds-update: "record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>"
    builds-distribute: "record<status: string, upload_id: string>"
    builds-get-download-uri: "record<uri: string>"
    builds-get-log: "record<value: list<string>>"
    commits-list-by-sha-list: "table<sha: string, url: string, commit: record<author: record, message: string>>"
    crash-groups-list: "record<continuation_token: string, crash_groups: table<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record, status: string>, limited_result_set: bool>"
    crash-groups-get: "record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string>"
    crash-groups-update: "record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string>"
    crashes-list: "table<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record, reason: string, threads: list, title: string>, timestamp: string, user_email: string, user_name: string, version: string>"
    crashes-delete: "record<app_id: string, attachments_deleted: int, blobs_failed: int, blobs_succeeded: int, crash_group_id: string, crash_id: string, crashes_deleted: int>"
    crashes-get: "record<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record<frames: list, inner_exceptions: list, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: list<record>, title: string>, timestamp: string, user_email: string, user_name: string, version: string>"
    crashes-get-native-crash: "string"
    crashes-get-native-crash-download: "string"
    crashes-get-raw-crash-location: "record<uri: string>"
    crashes-get-stacktrace: "record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>"
    crash-groups-get-stacktrace: "record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>"
    crashes-list-attachments: "table<app_id: string, attachment_id: string, blob_location: string, content_type: string, crash_id: string, created_time: string, file_name: string, size: float>"
    crashes-get-crash-attachment-location: "record<uri: string>"
    crashes-get-crash-text-attachment-content: "string"
    crashes-list-session-logs: "record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>"
    crashes-get-app-crashes-info: "record<features: record<crash_download_raw: bool, crashgroup_analytics_crashfreeusers: bool, crashgroup_analytics_impactedusers: bool, crashgroup_modify_annotation: bool, crashgroup_modify_status: bool, search: bool>, has_crashes: bool>"
    code-push-deployments-list: "table<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>"
    code-push-deployments-create: "record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>"
    code-push-deployments-get: "record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>"
    code-push-deployment-metrics-get: "table<active: int, downloaded: int, failed: int, installed: int, label: string>"
    code-push-deployments-promote: "record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>"
    code-push-deployment-releases-get: "table<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>"
    code-push-deployment-releases-create: "record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>"
    deployment-releases-update: "record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>"
    code-push-deployment-release-rollback: "record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>"
    code-push-deployment-upload-create: "record<id: string, token: string, upload_domain: string>"
    test-get-device-configurations: "table<id: string, image: record<full: string, thumb: string>, marketShare: float, model: record<availabilityCount: float, cpu: record, deviceFrame: record, dimensions: record, formFactor: string, manufacturer: string, memory: record, model: string, name: string, platform: string, releaseDate: string, resolution: record, screenRotation: float, screenSize: record>, name: string, os: string, osName: string, tier: float>"
    test-create-device-selection: "record<shortId: string>"
    app-block-logs: "string"
    devices-block-logs: "string"
    missing-symbol-groups-list: "record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int>"
    missing-symbol-groups-get: "record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int>"
    missing-symbol-groups-info: "record<total_crash_count: int>"
    distribution-groups-list: "table<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-create: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-get: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-update: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    devices-list: "table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>"
    distribution-groups-list-users: "table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string>"
    distribution-groups-add-user: "table<code: string, invite_pending: bool, message: string, status: int, user_email: string>"
    distribution-groups-remove-user: "table<code: string, message: int, status: int, user_email: string>"
    releases-list-by-distribution-group: "table<enabled: bool, id: int, is_external_build: bool, mandatory_update: bool, origin: string, short_version: string, uploaded_at: string, version: string>"
    releases-get-latest-by-distribution-group: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    stores-list: "table<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record, target_audience: record>, name: string, service_connection_id: string, track: string, type: string>"
    stores-create: "record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string>"
    stores-get: "record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string>"
    store-releases-get-latest: "table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string>"
    store-releases-list: "table<destination_type: string, distribution_stores: list<record>, id: float, short_version: string, uploaded_at: string, version: string>"
    store-releases-get: "table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string>"
    store-releases-get-publish-error: "record<is_log_available: bool, message: string>"
    store-releases-get-real-time-status-by-release-id: "record<app_id: string, release_id: string, status: record<status: string, storetype: string, track: string, version: string>>"
    errors-app-builds-list: "record<appBuilds: list<string>>"
    errors-available-versions: "record<total_count: int, versions: list<string>>"
    errors-counts-per-day: "record<count: int, errors: table<count: int, datetime: string>>"
    errors-group-list: "record<errorGroups: table<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: list, annotation: string, state: string>, nextLink: string>"
    errors-error-groups-search: "record<errorGroups: table<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: list, annotation: string, state: string>, hasMoreResults: bool>"
    errors-group-details: "record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, annotation: string, state: string>"
    errors-update-state: "record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, annotation: string, state: string>"
    errors-group-counts-per-day: "record<count: int, errors: table<count: int, datetime: string>>"
    errors-group-error-free-device-percentages: "record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>>"
    errors-list-for-group: "record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, nextLink: string>"
    errors-latest-error-details: "record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>"
    errors-delete-error: "record<appId: string, attachmentsDeleted: int, blobsFailed: int, blobsSucceeded: int, errorGroupId: string, errorId: string, errorsDeleted: int>"
    errors-get-error-details: "record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>"
    errors-error-download: "binary"
    errors-error-location: "record<uri: string>"
    errors-error-stack-trace: "record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>"
    errors-group-model-counts: "record<errorCount: int, models: table<errorCount: int, modelCode: string, modelName: string>>"
    errors-group-operating-system-counts: "record<errorCount: int, operatingSystems: table<errorCount: int, operatingSystemName: string>>"
    errors-group-error-stack-trace: "record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>"
    errors-error-free-device-percentages: "record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>>"
    errors-get-retention-settings: "record<retention_in_days: int>"
    errors-error-search: "record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, hasMoreResults: bool>"
    errors-error-attachments: "table<appId: string, attachmentId: string, blobLocation: string, contentType: string, crashId: string, createdTime: string, fileName: string, size: int>"
    errors-error-attachment-location: "record<uri: string>"
    errors-error-attachment-text: "record<content: string>"
    errors-list-session-logs: "record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>"
    export-configurations-list: "record<nextLink: string, total: int, values: table<creation_time: string, export_configuration: record, export_entities: list, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>>"
    export-configurations-create: "record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>"
    export-configurations-get: "record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>"
    export-configurations-partial-update: "record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>"
    file-assets-create: "record<id: string, location: string, token: string, uploadDomain: string, uploadWindowLocation: string, urlEncodedToken: string>"
    app-invitations-list: "record<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>, app_count: float, distribution_group: record<owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>>, email: string, id: string, invite_type: string, invited_by: record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>, is_existing_user: bool, permissions: list<string>>"
    notifications-get-app-email-settings: "record<request_id: string, eTag: string, enabled: bool, settings: table<default_value: string, event_type: string, value: string>, userId: string, appId: string, user_enabled: bool>"
    test-list-device-sets-of-owner: "table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-create-device-set-of-owner: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-get-device-set-of-owner: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-update-device-set-of-owner: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    releases-list-latest: "table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>"
    releases-list: "table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>"
    releases-available-to-tester: "table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>"
    releases-get-latest-by-user: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    releases-update: "record<release_notes: string>"
    releases-update-details: "record<destinations: table<id: string, name: string>, enabled: bool, mandatory_update: bool, provisioning_status_url: string, release_notes: string>"
    releases-add-distribution-group: "record<id: string, mandatory_update: bool, provisioning_status_url: string>"
    provisioning-profile: "record<appex_profiles: list<any>, provisioning_bundle_id: string, provisioning_profile_name: string, provisioning_profile_type: string, team_identifier: string, udids: list<string>>"
    releases-add-store: "record<id: string>"
    releases-add-testers: "record<id: string, mandatory_update: bool, provisioning_status_url: string>"
    devices-get-release-update-devices-status: "record<error_code: string, error_message: string, status: string>"
    repository-configurations-delete: "record<message: string>"
    repository-configurations-list: "table<id: string, state: string, type: string, user_email: string, installation_id: string, external_user_id: string, repo_id: string, repo_url: string, service_connection_id: string>"
    repository-configurations-create-or-update: "record<message: string>"
    repositories-list: "table<clone_url: string, name: string>"
    store-notifications-get-notification-by-app-id: "record<service: string, status: string, valid_until: int>"
    test-get-subscriptions: "record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>>"
    test-create-subscription: "record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>>"
    symbol-uploads-list: "table<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: list<record>, timestamp: string, user: record<display_name: string, email: string>>"
    symbol-uploads-create: "record<expiration_date: string, symbol_upload_id: string, upload_url: string>"
    symbol-uploads-delete: "record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>"
    symbol-uploads-get: "record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>"
    symbol-uploads-complete: "record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>"
    symbol-uploads-get-location: "record<uri: string>"
    symbols-list: "table<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>"
    symbols-get: "record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>"
    symbols-ignore: "record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>"
    symbols-get-location: "record<uri: string>"
    symbols-get-status: "record<app_id: string, status: string, symbol_id: string>"
    apps-get-teams: "table<description: string, display_name: string, id: string, name: string, permissions: list<string>>"
    test-gdpr-export-apps: "record<resources: table<path: string, rel: string>>"
    test-gdpr-export-app: "record<hash_files_url: string>"
    test-gdpr-export-file-set-file: "record<app_upload_id: string, hash_file_id: string, hash_file_url: string, path: string>"
    test-gdpr-export-hash-file: "record<filename: string, id: string>"
    test-gdpr-export-pipeline-test: "record<app_upload_id: string, test_parameters: record>"
    test-gdpr-export-test-run: "record<app_hash_file_id: string, app_hash_file_url: string, app_icon_url: string, dsym_hash_file_id: string, dsym_hash_file_url: string, id: string, locale: string>"
    test-get-test-runs: "table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>"
    test-archive-test-run: "record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>"
    test-get-test-run: "record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>"
    test-upload-hashes-batch: "table<checksum: string, fileType: string, relativePath: string, uploadStatus: record<location: string, statusCode: float>>"
    test-get-test-report: "record<app_upload_id: string, date: string, date_finished: string, device_logs: table<appium_log: string, device_log: string, device_snapshot_id: string, test_log: string>, errorMessage: string, features: table<failed: float, name: string, peakDuration: float, peakMemory: float, skipped: float, tests: list>, finished_device_snapshots: list<string>, id: string, platform: string, revision: float, schema_version: float, snapshot_fatal_errors: table<device_snapshot_id: string, error_message: string, error_title: string>, stats: record<artifacts: record, devices: float, devices_failed: float, devices_finished: float, devices_not_runned: float, devices_skipped: float, failed: float, filesize: float, os: float, passed: float, skipped: float, step_count: float, total: float, totalDeviceMinutes: float>, testType: string>"
    test-start-test-run: "record<accepted_devices: list<string>, rejected_devices: list<string>>"
    test-get-test-run-state: "record<exit_code: int, message: list<string>, wait_time: int>"
    test-stop-test-run: "record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>"
    test-get-all-test-series: "table<mostRecentActivity: string, name: string, slug: string, testRuns: list<record>>"
    test-create-test-series: "record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>>"
    test-patch-test-series: "record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>>"
    test-get-all-test-runs-for-series: "table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>"
    apps-list-testers: "table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>"
    builds-list-toolsets: "record<node: table<current: bool, name: string>, xamarin: table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list>, xcode: table<current: bool, name: string>>"
    apps-transfer-ownership: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-transfer-to-org: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    releases-create-release-upload: "record<id: string, package_asset_id: string, token: string, upload_domain: string, url_encoded_token: string>"
    releases-get-release-upload-status: "record<error_details: string, id: string, release_distinct_id: float, release_url: any, upload_status: string>"
    releases-update-release-upload-status: "record<id: string, upload_status: string>"
    test-list-device-sets-of-user: "table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-create-device-set-of-user: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-get-device-set-of-user: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    test-update-device-set-of-user: "record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>"
    users-list: "table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>"
    crashes-get-app-versions: "table<app_id: string, app_version: string, app_version_id: string, build_number: string, display_name: string>"
    webhooks-list: "record<values: table<enabled: bool, event_types: list, id: string, name: string, url: string>>"
    builds-list-xamarin-sdk-bundles: "table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list<string>>"
    builds-list-xcode-versions: "table<current: bool, name: string>"
    azure-subscription-list-for-user: "table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>"
    billing-aggregated-information-get-all: "record<aggregatedBillings: record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record, testService: record>, id: string, timestamp: string, usage: record<buildService: record, testService: record>, version: string>>"
    invitations-sent: "table<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record, release_type: string, app_secret: string, azure_subscription: record, created_at: string, member_permissions: list, origin: string, platform: string, updated_at: string>, invitation_id: string, organization: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>>"
    legacy-code-push-acquisition-update-check: "record<updateInfo: record<appVersion: string, description: string, isDisabled: bool, isMandatory: bool, rollout: int, downloadURL: string, isAvailable: bool, label: string, packageHash: string, packageSize: float, shouldRunBinaryVersion: bool, updateAppVersion: bool>>"
    organizations-list: "table<display_name: string, name: string, origin: string>"
    organizations-create-or-update: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    billing-aggregated-information-get-for-org: "record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string>"
    organizations-get: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    organizations-update: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    apps-list-for-org: "table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    apps-create-for-org: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    organization-delete-avatar: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    organization-update-avatar: "record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>"
    azure-subscription-list-for-org: "table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>"
    distribution-groups-list-for-org: "table<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-create-for-org: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-get-for-org: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-patch-for-org: "record<display_name: string, id: string, is_public: bool, name: string, origin: string>"
    distribution-groups-get-apps: "table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, origin: string, platform: string>"
    distribution-groups-list-users-for-org: "table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string>"
    distribution-groups-add-users-for-org: "table<code: string, invite_pending: bool, message: string, status: int, user_email: string>"
    distribution-groups-details-for-org: "table<display_name: string, id: string, is_public: bool, name: string, origin: string, apps: list<record>, total_apps_count: float, total_users_count: float>"
    org-invitations-list-pending: "table<email: string, id: string, role: string>"
    teams-list-all: "table<description: string, display_name: string, id: string, name: string>"
    teams-create-team: "table<description: string, display_name: string, id: string, name: string>"
    teams-get-team: "record<description: string, display_name: string, id: string, name: string>"
    teams-update: "record<description: string, display_name: string, id: string, name: string>"
    teams-list-apps: "table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>"
    teams-add-app: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>"
    teams-update-permissions: "record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>"
    teams-get-users: "record<display_name: string, email: string, name: string, role: any>"
    teams-add-user: "record<display_name: string, email: string, name: string, role: any>"
    distribution-groups-list-all-testers-for-org: "table<display_name: string, email: string, name: string>"
    users-list-for-org: "table<display_name: string, email: string, joined_at: string, name: string, role: string>"
    users-get-for-org: "record<display_name: string, email: string, joined_at: string, name: string, role: string>"
    users-update-org-role: "record<display_name: string, email: string, joined_at: string, name: string, role: string>"
    apps-get-for-org-user: "table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>"
    code-push-acquisition-get-acquisition-status: "record<code: string, message: string>"
    code-push-acquisition-update-check: "record<update_info: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, download_url: string, is_available: bool, label: string, package_hash: string, package_size: float, should_run_binary_version: bool, update_app_version: bool>>"
    releases-get-latest-by-public-distribution-group: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    releases-get-latest-public-release: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    releases-get-public-groups-for-release-by-hash: "table<id: string>"
    releases-get-latest-private-release: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    releases-get-latest-by-hash: "record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>"
    users-get: "record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>"
    users-update: "record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>"
    devices-user-devices-list: "table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>"
    devices-device-details: "record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>"
    data-subject-right-delete-request: "record<createdAt: string, token: string>"
    data-subject-right-delete-status-request: "record<message: string, sasUrl: string, sasUrlExpired: bool, status: string>"
    data-subject-right-cancel-delete-request: "record<createdAt: string, token: string>"
    data-subject-right-export-request: "record<createdAt: string, token: string>"
    data-subject-right-export-status-request: "record<message: string, sasUrl: string, sasUrlExpired: bool, status: string>"
    data-subject-right-cancel-export-request: "record<createdAt: string, token: string>"
    sharedconnection-connections: "table<credentialType: string, displayName: string, serviceType: string>"
    users-get-user-metadata: "record<metadata: record, userId: string>"
    notifications-get-user-email-settings: "record<request_id: string, eTag: string, enabled: bool, settings: table<default_value: string, event_type: string, value: string>, userId: string>"
    devices-register-user-for-device: "record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["test-gdpr-export-accounts" "test-gdpr-export-account" "test-gdpr-export-feature-flag" "organizations-list-administered" "user-api-tokens-list" "user-api-tokens-new" "user-api-tokens-delete" "apps-list" "apps-create" "apps-delete" "apps-get" "apps-update" "analytics-device-counts" "analytics-list-audiences" "analytics-test-audience" "analytics-list-custom-properties" "analytics-list-device-properties" "analytics-list-device-property-values" "analytics-delete-audience" "analytics-get-audience" "analytics-audience-name-exists" "analytics-create-or-update-audience" "analytics-crash-counts" "analytics-crash-groups-totals" "analytics-crash-group-counts" "analytics-crash-group-model-counts" "analytics-crash-group-operating-system-counts" "analytics-crash-group-totals" "analytics-crash-free-device-percentages" "analytics-distribution-release-counts" "analytics-events-delete-logs" "analytics-events" "analytics-events-delete" "analytics-event-per-device-count" "analytics-event-per-session-count" "analytics-event-device-count" "analytics-event-count" "analytics-event-properties" "analytics-event-property-counts" "analytics-generic-log-flow" "analytics-language-counts" "analytics-log-flow" "analytics-model-counts" "analytics-operating-system-counts" "analytics-place-counts" "analytics-session-counts" "analytics-session-durations-distribution" "analytics-per-device-counts" "analytics-versions" "app-api-tokens-list" "app-api-tokens-new" "app-api-tokens-delete" "apple-mapping-delete" "apple-mapping-get" "apple-mapping-create" "apple-mapping-test-flight-groups" "apps-delete-avatar" "apps-update-avatar" "azure-subscription-list-for-app" "azure-subscription-link-for-app" "azure-subscription-delete-for-app" "billing-aggregated-information-get-by-app" "builds-list-branches" "builds-list-by-branch" "builds-create" "branch-configurations-delete" "branch-configurations-get" "branch-configurations-create" "branch-configurations-update" "build-configurations-get" "builds-list-toolset-projects" "bugtracker-get-settings" "bug-tracker-get-repo-issue-from-crash" "builds-get-status-by-app-id" "builds-get" "builds-update" "builds-distribute" "builds-get-download-uri" "builds-get-log" "commits-list-by-sha-list" "crash-groups-list" "crash-groups-get" "crash-groups-update" "crashes-list" "crashes-delete" "crashes-get" "crashes-get-native-crash" "crashes-get-native-crash-download" "crashes-get-raw-crash-location" "crashes-get-stacktrace" "crash-groups-get-stacktrace" "crashes-list-attachments" "crashes-get-crash-attachment-location" "crashes-get-crash-text-attachment-content" "crashes-list-session-logs" "crashes-get-app-crashes-info" "code-push-deployments-list" "code-push-deployments-create" "code-push-deployments-delete" "code-push-deployments-get" "code-push-deployments-update" "code-push-deployment-metrics-get" "code-push-deployments-promote" "code-push-deployment-releases-delete" "code-push-deployment-releases-get" "code-push-deployment-releases-create" "deployment-releases-update" "code-push-deployment-release-rollback" "code-push-deployment-upload-create" "test-get-device-configurations" "test-create-device-selection" "app-block-logs" "devices-block-logs" "missing-symbol-groups-list" "missing-symbol-groups-get" "missing-symbol-groups-info" "distribution-groups-list" "distribution-groups-create" "distribution-groups-delete" "distribution-groups-get" "distribution-groups-update" "devices-list" "devices-list-csv-format" "distribution-groups-list-users" "distribution-groups-add-user" "distribution-groups-remove-user" "releases-list-by-distribution-group" "releases-delete-with-distribution-group-id" "releases-get-latest-by-distribution-group" "distribution-groups-resend-invite" "stores-list" "stores-create" "stores-delete" "stores-get" "stores-patch" "store-releases-get-latest" "store-releases-list" "store-releases-delete" "store-releases-get" "store-releases-get-publish-error" "store-release-publish-logs-get" "store-releases-get-real-time-status-by-release-id" "errors-app-builds-list" "errors-available-versions" "errors-counts-per-day" "errors-group-list" "errors-error-groups-search" "errors-group-details" "errors-update-state" "errors-group-counts-per-day" "errors-group-error-free-device-percentages" "errors-list-for-group" "errors-latest-error-details" "errors-delete-error" "errors-get-error-details" "errors-error-download" "errors-error-location" "errors-error-stack-trace" "errors-group-model-counts" "errors-group-operating-system-counts" "errors-group-error-stack-trace" "errors-error-free-device-percentages" "errors-get-retention-settings" "errors-error-search" "errors-error-attachments" "errors-error-attachment-location" "errors-error-attachment-text" "errors-list-session-logs" "export-configurations-list" "export-configurations-create" "export-configurations-delete" "export-configurations-get" "export-configurations-partial-update" "export-configurations-disable" "export-configurations-enable" "file-assets-create" "app-invitations-list" "app-invitations-create" "app-invitations-delete" "app-invitations-update-permissions" "app-invitations-create-by-email" "notifications-get-app-email-settings" "test-list-device-sets-of-owner" "test-create-device-set-of-owner" "test-delete-device-set-of-owner" "test-get-device-set-of-owner" "test-update-device-set-of-owner" "releases-list-latest" "releases-list" "releases-available-to-tester" "releases-delete" "releases-get-latest-by-user" "releases-update" "releases-update-details" "releases-add-distribution-group" "releases-delete-distribution-group" "releases-put-distribution-group" "provisioning-profile" "releases-add-store" "releases-delete-distribution-store" "releases-add-testers" "releases-delete-distribution-tester" "releases-put-distribution-tester" "devices-get-release-update-devices-status" "repository-configurations-delete" "repository-configurations-list" "repository-configurations-create-or-update" "repositories-list" "store-notifications-get-notification-by-app-id" "test-get-subscriptions" "test-create-subscription" "symbol-uploads-list" "symbol-uploads-create" "symbol-uploads-delete" "symbol-uploads-get" "symbol-uploads-complete" "symbol-uploads-get-location" "symbols-list" "symbols-get" "symbols-ignore" "symbols-get-location" "symbols-get-status" "apps-get-teams" "test-gdpr-export-apps" "test-gdpr-export-app" "test-gdpr-export-file-set-file" "test-gdpr-export-hash-file" "test-gdpr-export-pipeline-test" "test-gdpr-export-test-run" "test-get-test-runs" "test-create-test-run" "test-archive-test-run" "test-get-test-run" "test-start-uploading-file" "test-upload-hash" "test-upload-hashes-batch" "test-get-test-report" "test-start-test-run" "test-get-test-run-state" "test-stop-test-run" "test-get-all-test-series" "test-create-test-series" "test-delete-test-series" "test-patch-test-series" "test-get-all-test-runs-for-series" "apps-list-testers" "releases-delete-tester-from-destinations" "builds-list-toolsets" "apps-transfer-ownership" "apps-transfer-to-org" "releases-create-release-upload" "releases-get-release-upload-status" "releases-update-release-upload-status" "test-list-device-sets-of-user" "test-create-device-set-of-user" "test-delete-device-set-of-user" "test-get-device-set-of-user" "test-update-device-set-of-user" "users-list" "apps-remove-user" "apps-update-user-permissions" "crashes-get-app-versions" "webhooks-list" "builds-list-xamarin-sdk-bundles" "builds-list-xcode-versions" "azure-subscription-list-for-user" "billing-aggregated-information-get-all" "invitations-sent" "legacy-code-push-acquisition-update-installs-status" "legacy-code-push-acquisition-update-download-status" "legacy-code-push-acquisition-update-check" "organizations-list" "organizations-create-or-update" "billing-aggregated-information-get-for-org" "organizations-delete" "organizations-get" "organizations-update" "apps-list-for-org" "apps-create-for-org" "organization-delete-avatar" "organization-update-avatar" "azure-subscription-list-for-org" "distribution-groups-list-for-org" "distribution-groups-create-for-org" "distribution-groups-delete-for-org" "distribution-groups-get-for-org" "distribution-groups-patch-for-org" "distribution-groups-get-apps" "distribution-groups-add-apps" "distribution-groups-bulk-delete-apps" "distribution-groups-list-users-for-org" "distribution-groups-add-users-for-org" "distribution-groups-bulk-delete-users" "distribution-groups-resend-shared-invite" "distribution-groups-details-for-org" "org-invitations-delete" "org-invitations-list-pending" "org-invitations-create" "org-invitations-update" "org-invitations-send-new-invitation" "org-invitations" "teams-list-all" "teams-create-team" "teams-delete" "teams-get-team" "teams-update" "teams-list-apps" "teams-add-app" "teams-remove-app" "teams-update-permissions" "teams-get-users" "teams-add-user" "teams-remove-user" "distribution-groups-list-all-testers-for-org" "users-list-for-org" "users-remove-from-org" "users-get-for-org" "users-update-org-role" "apps-get-for-org-user" "releases-get-ios-manifest" "distibution-releases-install-analytics" "code-push-acquisition-update-deploy-status" "code-push-acquisition-update-download-status" "code-push-acquisition-get-acquisition-status" "code-push-acquisition-update-check" "builds-webhook" "releases-get-latest-by-public-distribution-group" "releases-get-latest-public-release" "releases-get-public-groups-for-release-by-hash" "releases-get-sparkle-feed" "releases-get-latest-private-release" "releases-get-latest-by-hash" "users-get" "users-update" "devices-user-devices-list" "devices-remove-user-device" "devices-device-details" "data-subject-right-delete-request" "data-subject-right-delete-status-request" "data-subject-right-cancel-delete-request" "data-subject-right-export-request" "data-subject-right-export-status-request" "data-subject-right-cancel-export-request" "sharedconnection-connections" "app-invitations-accept" "app-invitations-reject" "distribution-group-invitations-accept-all" "org-invitations-accept" "org-invitations-reject" "users-get-user-metadata" "notifications-get-user-email-settings" "devices-register-user-for-device" "commands"] | sort) } | get name | first)
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

# Lists all the endpoints available for Test accounts data
#
# GET /v0.1/account/test/export
# Returns: record<resources: table<path: string, rel: string>>
# operationId: test_gdprExportAccounts
export def "test-gdpr-export-accounts" [
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
    path: "/v0.1/account/test/export"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists account data
#
# GET /v0.1/account/test/export/accounts
# Returns: record<id: string>
# operationId: test_gdprExportAccount
export def "test-gdpr-export-account" [
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
    path: "/v0.1/account/test/export/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists feature flag data
#
# GET /v0.1/account/test/export/featureFlags
# Returns: record<name: string, target_id: string>
# operationId: test_gdprExportFeatureFlag
export def "test-gdpr-export-feature-flag" [
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
    path: "/v0.1/account/test/export/featureFlags"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list organizations in which the requesting user is an admin
#
# GET /v0.1/administeredOrgs
# Returns: record<organizations: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>>
# operationId: organizations_listAdministered
export def "organizations-list-administered" [
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
    path: "/v0.1/administeredOrgs"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns api tokens for the authenticated user
#
# GET /v0.1/api_tokens
# Returns: table<created_at: string, description: string, id: string, scope: list<string>>
# operationId: userApiTokens_list
export def "user-api-tokens-list" [
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
    path: "/v0.1/api_tokens"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new User API token
#
# POST /v0.1/api_tokens
# Returns: record<api_token: string, created_at: string, description: string, id: string, scope: list<string>>
# operationId: userApiTokens_new
export def "user-api-tokens-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the token
  --scope: list<string> # The scope for this token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/api_tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    description: $description, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the user api_token object with the specific id
#
# DELETE /v0.1/api_tokens/{api_token_id}
# operationId: userApiTokens_delete
export def "user-api-tokens-delete" [
  api_token_id: string
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
    path: "/v0.1/api_tokens/{api_token_id}"
    path_params: [{name: api_token_id, var: api_token_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    api_token_id: $api_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of apps
#
# GET /v0.1/apps
# Returns: table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_list
export def "apps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer # The name of the attribute by which to order the response by. By default, apps are in order of creation. All results are ordered in ascending order.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps"
    query: [{name: "$orderBy", var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new app and returns it to the caller
#
# POST /v0.1/apps
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_create
export def "apps-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  display_name: string # The descriptive name of the app. This can contain any characters
  --name: string # The name of the app used in URLs
  os: string@os-completer # The OS the app will be running on
  platform: string@platform-completer # The platform of the app
  --release-type: string # A one-word descriptive release-type value that starts with a capital letter but is otherwise lowercase
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: name, var: name}, {name: os, var: os}, {name: platform, var: platform}, {name: release_type, var: release_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    description: $description, display_name: $display_name, name: $name, os: $os, platform: $platform, release_type: $release_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}
# operationId: apps_delete
export def "apps-delete" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a specific app with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_get
export def "apps-get" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially updates a single app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_update
export def "apps-update" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  --display-name: string # The display name of the app
  --icon-asset-id: string # The uuid for the icon's asset id from ACFUS (format: uuid)
  --icon-url: string # The string representation of the URL pointing to the app's icon
  --name: string # The name of the app used in URLs
  --release-type: string # A one-word descriptive release type value that starts with a capital letter but is otherwise lowercase
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: icon_asset_id, var: icon_asset_id}, {name: icon_url, var: icon_url}, {name: name, var: name}, {name: release_type, var: release_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, description: $description, display_name: $display_name, icon_asset_id: $icon_asset_id, icon_url: $icon_url, name: $name, release_type: $release_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of active devices by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/active_device_counts
# Returns: record<daily: table<count: int, datetime: string>, monthly: table<count: int, datetime: string>, weekly: table<count: int, datetime: string>>
# operationId: Analytics_DeviceCounts
export def "analytics-device-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --app-build: string # Application build number. If build number is specified than multiple versions are not allowed. (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/active_device_counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}, {name: app_build, var: app_build}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions, app_build: $app_build
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of audiences.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences
# Returns: record<nextLink: string, values: table<definition: string, description: string, estimated_count: int, name: string, state: string>>
# operationId: Analytics_ListAudiences
export def "analytics-list-audiences" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-disabled: oneof<nothing, bool> # Include disabled audience definitions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: include_disabled, var: include_disabled}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, include_disabled: $include_disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests audience definition.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/definition/test
# Returns: record<custom_properties: record, definition: string, estimated_count: int, estimated_total_count: int>
# operationId: Analytics_TestAudience
export def "analytics-test-audience" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: record # Custom properties used in the definition.
  definition: string # Audience definition in OData format.
  --description: string # Audience description.
  --enabled: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/definition/test"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_properties, var: custom_properties}, {name: definition, var: definition}, {name: description, var: description}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, custom_properties: $custom_properties, definition: $definition, description: $description, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of custom properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/custom_properties
# Returns: record<values: record>
# operationId: Analytics_ListCustomProperties
export def "analytics-list-custom-properties" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/custom_properties"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of device properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties
# Returns: record<values: record>
# operationId: Analytics_ListDeviceProperties
export def "analytics-list-device-properties" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of device property values.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties/{property_name}/values
# Returns: record<values: list<string>>
# operationId: Analytics_ListDevicePropertyValues
export def "analytics-list-device-property-values" [
  owner_name: string
  app_name: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contains: string # Contains string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/metadata/device_properties/{property_name}/values"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: property_name, var: property_name}]
    query: [{name: contains, var: contains}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, property_name: $property_name, contains: $contains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes audience definition.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# operationId: Analytics_DeleteAudience
export def "analytics-delete-audience" [
  owner_name: string
  app_name: string
  audience_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: audience_name, var: audience_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, audience_name: $audience_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets audience definition.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# Returns: record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string>
# operationId: Analytics_GetAudience
export def "analytics-get-audience" [
  owner_name: string
  app_name: string
  audience_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: audience_name, var: audience_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, audience_name: $audience_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns whether audience definition exists.
#
# HEAD /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# Returns: record
# operationId: Analytics_AudienceNameExists
export def "analytics-audience-name-exists" [
  owner_name: string
  app_name: string
  audience_name: string
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
    method: head
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: audience_name, var: audience_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, audience_name: $audience_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates audience definition.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}
# Returns: record<custom_properties: record, enabled: bool, estimated_total_count: int, timestamp: string, definition: string, description: string, estimated_count: int, name: string, state: string>
# operationId: Analytics_CreateOrUpdateAudience
export def "analytics-create-or-update-audience" [
  owner_name: string
  app_name: string
  audience_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-properties: record # Custom properties used in the definition.
  definition: string # Audience definition in OData format.
  --description: string # Audience description.
  --enabled: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/audiences/{audience_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: audience_name, var: audience_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_properties, var: custom_properties}, {name: definition, var: definition}, {name: description, var: description}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, audience_name: $audience_name, custom_properties: $custom_properties, definition: $definition, description: $description, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_counts
# DEPRECATED
# Returns: record<count: int, crashes: table<count: int, datetime: string>>
# operationId: Analytics_CrashCounts
@deprecated
export def "analytics-crash-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overall crashes and affected users count of the selected crash groups with selected versions.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups
# Returns: table<app_version: string, crash_group_id: string, overall: record<crash_count: int, device_count: int>>
# operationId: Analytics_CrashGroupsTotals
export def "analytics-crash-groups-totals" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  crash_groups: list # item shape: {app_version?: string, crash_group_id?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: crash_groups, var: crash_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_groups: $crash_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/crash_counts
# DEPRECATED
# Returns: record<count: int, crashes: table<count: int, datetime: string>>
# operationId: Analytics_CrashGroupCounts
@deprecated
export def "analytics-crash-group-counts" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # required, format: string
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/crash_counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: version, var: version, required: true}, {name: start, var: start, required: true}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, version: $version, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/models
# DEPRECATED
# Returns: record<crash_count: int, models: table<crash_count: int, model_name: string>>
# operationId: Analytics_CrashGroupModelCounts
@deprecated
export def "analytics-crash-group-model-counts" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # required, format: string
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/models"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: version, var: version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, version: $version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/operating_systems
# DEPRECATED
# Returns: record<crash_count: int, operating_systems: table<crash_count: int, operating_system_name: string>>
# operationId: Analytics_CrashGroupOperatingSystemCounts
@deprecated
export def "analytics-crash-group-operating-system-counts" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # required, format: string
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/operating_systems"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: version, var: version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, version: $version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Available for UWP apps only.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/overall
# DEPRECATED
# Returns: record<crash_count: int, device_count: int>
# operationId: Analytics_CrashGroupTotals
@deprecated
export def "analytics-crash-group-totals" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # required, format: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crash_groups/{crash_group_id}/overall"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: version, var: version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Percentage of crash-free device by day in the time range based on the selected versions. Api will return -1 if crash devices is greater than active devices.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/crashfree_device_percentages
# DEPRECATED
# Returns: record<average_percentage: float, daily_percentages: table<datetime: string, percentage: float>>
# operationId: Analytics_CrashFreeDevicePercentages
@deprecated
export def "analytics-crash-free-device-percentages" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --version: string # required, format: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/crashfree_device_percentages"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: version, var: version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of total downloads for the provided distribution releases.
#
# POST /v0.1/apps/{owner_name}/{app_name}/analytics/distribution/release_counts
# Returns: record<counts: table<distribution_group: string, release_id: string, total_count: int, unique_count: int>, total: int>
# operationId: Analytics_DistributionReleaseCounts
export def "analytics-distribution-release-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  releases: list # item shape: {distribution_group?: string, release: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/distribution/release_counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: releases, var: releases}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, releases: $releases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the set of Events with the specified event names.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/event_logs/{event_name}
# operationId: Analytics_EventsDeleteLogs
export def "analytics-events-delete-logs" [
  owner_name: string
  app_name: string
  event_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/event_logs/{event_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of active events in the time range ordered by event.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events
# Returns: record<events: table<count: int, count_per_device: float, count_per_session: float, device_count: int, id: string, name: string, previous_count: int, previous_device_count: int>, total: int, total_devices: int>
# operationId: Analytics_Events
export def "analytics-events" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --event-name: list<string> # To select the specific events.
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
  --inlinecount: string@inlinecount-completer # Controls whether or not to include a count of all the items across all pages. (default: none)
  --orderby: string # controls the sorting order and sorting based on which column (default: count desc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}, {name: event_name, var: event_name, style: pipes}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: "$inlinecount", var: inlinecount}, {name: "$orderby", var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions, event_name: $event_name, top: $top, skip: $skip, inlinecount: $inlinecount, orderby: $orderby
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the set of Events with the specified event names.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}
# operationId: Analytics_EventsDelete
export def "analytics-events-delete" [
  owner_name: string
  app_name: string
  event_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of events per device by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_device
# Returns: record<avg_count_per_device: float, count_per_device: table<count: float, datetime: string>, previous_avg_count_per_device: float>
# operationId: Analytics_EventPerDeviceCount
export def "analytics-event-per-device-count" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_device"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of events per session by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_session
# Returns: record<avg_count_per_session: float, count_per_session: table<count: float, datetime: string>, previous_avg_count_per_session: float>
# operationId: Analytics_EventPerSessionCount
export def "analytics-event-per-session-count" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/count_per_session"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of devices for an event by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/device_count
# Returns: record<devices_count: table<count: int, datetime: string>, previous_total_devices_with_event: int, total_devices: int, total_devices_with_event: int>
# operationId: Analytics_EventDeviceCount
export def "analytics-event-device-count" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/device_count"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of events by interval in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/event_count
# Returns: record<count: table<count: int, datetime: string>, previous_total_count: int, total_count: int>
# operationId: Analytics_EventCount
export def "analytics-event-count" [
  owner_name: string
  app_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/event_count"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event properties.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties
# Returns: record<event_properties: list<string>>
# operationId: Analytics_EventProperties
export def "analytics-event-properties" [
  owner_name: string
  app_name: string
  event_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Event properties value counts during the time range in descending order.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties/{event_property_name}/counts
# Returns: record<total: int, values: table<count: int, name: string, previous_count: int>>
# operationId: Analytics_EventPropertyCounts
export def "analytics-event-property-counts" [
  owner_name: string
  app_name: string
  event_name: string
  event_property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
  --top: int # The number of property values to return. Set to 0 in order to fetch all results available. (format: int64, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/events/{event_name}/properties/{event_property_name}/counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: event_name, var: event_name}, {name: event_property_name, var: event_property_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, event_name: $event_name, event_property_name: $event_property_name, start: $start, end: $end, versions: $versions, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs received between the specified start time and the current time. The API will return a maximum of 100 logs per call.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/generic_log_flow
# Returns: record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>
# operationId: Analytics_GenericLogFlow
export def "analytics-generic-log-flow" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. It must be within the current day in the UTC timezone. The default value is the start time of the current day in UTC timezone. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/generic_log_flow"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Languages in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/languages
# Returns: record<languages: table<count: int, language_name: string, previous_count: int>, total: int>
# operationId: Analytics_LanguageCounts
export def "analytics-language-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/languages"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs received between the specified start time and the current time. The API will return a maximum of 100 logs per call.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/log_flow
# Returns: record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, install_id: string, timestamp: string, type: string>>
# operationId: Analytics_LogFlow
export def "analytics-log-flow" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. It must be within the current day in the UTC timezone. The default value is the start time of the current day in UTC timezone. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/log_flow"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Models in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/models
# Returns: record<models: table<count: int, model_name: string, previous_count: int>, total: int>
# operationId: Analytics_ModelCounts
export def "analytics-model-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/models"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OSes in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/oses
# Returns: record<oses: table<count: int, os_name: string, previous_count: int>, total: int>
# operationId: Analytics_OperatingSystemCounts
export def "analytics-operating-system-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/oses"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/places
# Returns: record<places: table<code: string, count: int, previous_count: int>, total: int>
# operationId: Analytics_PlaceCounts
export def "analytics-place-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/places"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of sessions in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/session_counts
# Returns: table<count: int, datetime: string>
# operationId: Analytics_SessionCounts
export def "analytics-session-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/session_counts"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets session duration.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/session_durations_distribution
# Returns: record<average_duration: string, distribution: table<bucket: string, count: int>, previous_average_duration: string>
# operationId: Analytics_SessionDurationsDistribution
export def "analytics-session-durations-distribution" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/session_durations_distribution"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of sessions per device in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/sessions_per_device
# Returns: record<average_sessions_per_user: float, previous_average_sessions_per_user: float, previous_total_count: int, sessions_per_user: table<count: float, datetime: string>, total_count: int>
# operationId: Analytics_PerDeviceCounts
export def "analytics-per-device-counts" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/sessions_per_device"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of active versions in the time range ordered by version.
#
# GET /v0.1/apps/{owner_name}/{app_name}/analytics/versions
# Returns: record<total: int, versions: table<count: int, previous_count: int, version: string>>
# operationId: Analytics_Versions
export def "analytics-versions" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format. (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format. (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results) (format: int64, default: 30)
  --versions: list<string> # To select specific application versions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/analytics/versions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: versions, var: versions, style: pipes}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, versions: $versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns App API tokens for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/api_tokens
# Returns: table<created_at: string, description: string, id: string, scope: list<string>>
# operationId: appApiTokens_list
export def "app-api-tokens-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/api_tokens"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new App API token
#
# POST /v0.1/apps/{owner_name}/{app_name}/api_tokens
# Returns: record<api_token: string, created_at: string, description: string, id: string, scope: list<string>>
# operationId: appApiTokens_new
export def "app-api-tokens-new" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the token
  --scope: list<string> # The scope for this token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/api_tokens"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [201]
    auth: basic
  } {
    owner_name: $owner_name, app_name: $app_name, description: $description, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the App Api Token object with the specific ID
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/api_tokens/{api_token_id}
# operationId: appApiTokens_delete
export def "app-api-tokens-delete" [
  owner_name: string
  app_name: string
  api_token_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/api_tokens/{api_token_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: api_token_id, var: api_token_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    owner_name: $owner_name, app_name: $app_name, api_token_id: $api_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete mapping of apple app to an existing app in apple store.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# operationId: appleMapping_delete
export def "apple-mapping-delete" [
  owner_name: string
  app_name: string
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
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get mapping of apple app to an existing app in apple store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# Returns: record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string>
# operationId: appleMapping_get
export def "apple-mapping-get" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a mapping for an existing app in apple store for the specified application.
#
# POST /v0.1/apps/{owner_name}/{app_name}/apple_mapping
# Returns: record<app_id: string, apple_id: string, service_connection_id: string, team_identifier: string>
# operationId: appleMapping_create
export def "apple-mapping-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apple-id: string # ID of the apple application in apple store, takes precedence over bundle_identifier when both are provided
  --bundle-identifier: string # Bundle Identifier of the apple package
  service_connection_id: string # Id for the shared service connection. In case of Apple AppStore, this connection will be used to create and connect to the Apple AppStore in Mobile Center.
  team_identifier: string # ID of the Team associated with the app in apple store
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/apple_mapping"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: apple_id, var: apple_id}, {name: bundle_identifier, var: bundle_identifier}, {name: service_connection_id, var: service_connection_id}, {name: team_identifier, var: team_identifier}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, apple_id: $apple_id, bundle_identifier: $bundle_identifier, service_connection_id: $service_connection_id, team_identifier: $team_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch all apple test flight groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/apple_test_flight_groups
# DEPRECATED
# Returns: table<appleId: float, id: string, name: string, providerId: float>
# operationId: appleMapping_TestFlightGroups
@deprecated
export def "apple-mapping-test-flight-groups" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/apple_test_flight_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the uploaded app avatar
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/avatar
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_deleteAvatar
export def "apps-delete-avatar" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/avatar"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the app avatar
#
# POST /v0.1/apps/{owner_name}/{app_name}/avatar
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_updateAvatar
export def "apps-update-avatar" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The image for an app avatar to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/avatar"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: avatar, var: avatar}], files: [avatar]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, avatar: $avatar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of azure subscriptions for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions
# Returns: table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>
# operationId: azureSubscription_listForApp
export def "azure-subscription-list-for-app" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Link azure subscription to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions
# operationId: azureSubscription_linkForApp
export def "azure-subscription-link-for-app" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  subscription_id: string # The azure subscription id (format: uuid)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: subscription_id, var: subscription_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the azure subscriptions for the app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/azure_subscriptions/{azure_subscription_id}
# operationId: azureSubscription_deleteForApp
export def "azure-subscription-delete-for-app" [
  owner_name: string
  app_name: string
  azure_subscription_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/azure_subscriptions/{azure_subscription_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: azure_subscription_id, var: azure_subscription_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, azure_subscription_id: $azure_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated Billing Information for owner of a given app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/billing/aggregated
# Returns: record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string>
# operationId: billingAggregatedInformation_getByApp
export def "billing-aggregated-information-get-by-app" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/billing/aggregated"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: service, var: service}, {name: period, var: period}, {name: showOriginalPlans, var: show_original_plans}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, service: $service, period: $period, show_original_plans: $show_original_plans
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of Git branches for this application
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches
# Returns: table<configured: bool, lastBuild: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>>
# operationId: builds_listBranches
export def "builds-list-branches" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/branches"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of builds for the branch
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds
# Returns: table<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>
# operationId: builds_listByBranch
export def "builds-list-by-branch" [
  owner_name: string
  app_name: string
  branch: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a build
#
# POST /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds
# Returns: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>
# operationId: builds_create
export def "builds-create" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --debug: oneof<nothing, bool> # Run build in debug mode
  --source-version: string # Version to build which represents the full Git commit reference
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/builds"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    body: {content_type: "application/json", kind: json, fields: [{name: debug, var: debug}, {name: sourceVersion, var: source_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, debug: $debug, source_version: $source_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the branch build configuration
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# Returns: record<message: string>
# operationId: branchConfigurations_delete
export def "branch-configurations-delete" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the branch configuration
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# Returns: record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>
# operationId: branchConfigurations_get
export def "branch-configurations-get" [
  owner_name: string
  app_name: string
  branch: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures the branch for build
#
# POST /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# Returns: record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>
# operationId: branchConfigurations_create
export def "branch-configurations-create" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-versioning: record # The versioning configuration for artifacts built for this branch — shape: {buildNumberFormat?: "buildId"|"timestamp"}
  --badge-is-enabled: oneof<nothing, bool>
  --clone-from-branch: string # A configured branch name to clone from. If provided, all other parameters will be ignored. Only supported in POST requests.
  --signed: oneof<nothing, bool>
  --tests-enabled: oneof<nothing, bool>
  --toolsets: any # The branch build configuration for each toolset — shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
  --trigger: string@trigger-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    body: {content_type: "application/json", kind: json, fields: [{name: artifactVersioning, var: artifact_versioning}, {name: badgeIsEnabled, var: badge_is_enabled}, {name: cloneFromBranch, var: clone_from_branch}, {name: signed, var: signed}, {name: testsEnabled, var: tests_enabled}, {name: toolsets, var: toolsets}, {name: trigger, var: trigger}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, artifact_versioning: $artifact_versioning, badge_is_enabled: $badge_is_enabled, clone_from_branch: $clone_from_branch, signed: $signed, tests_enabled: $tests_enabled, toolsets: $toolsets, trigger: $trigger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconfigures the branch for build
#
# PUT /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config
# Returns: record<artifactVersioning: record<buildNumberFormat: string>, badgeIsEnabled: bool, cloneFromBranch: string, signed: bool, testsEnabled: bool, toolsets: record<android: record<automaticSigning: bool, buildVariant: string, gradleWrapperPath: string, isRoot: bool, keyAlias: string, keyPassword: string, keystoreEncoded: string, keystoreFilename: string, keystorePassword: string, module: string, runLint: bool, runTests: bool>, javascript: record<packageJsonPath: string, reactNativeVersion: string, runTests: bool>, xamarin: record<args: string, configuration: string, isSimBuild: bool, monoVersion: string, p12File: string, p12Pwd: string, provProfile: string, sdkBundle: string, slnPath: string, symlink: string>, xcode: record<appExtensionProvisioningProfileFiles: list, archiveConfiguration: string, automaticSigning: bool, cartfilePath: string, certificateEncoded: string, certificateFileId: string, certificateFilename: string, certificatePassword: string, certificateUploadId: string, forceLegacyBuildSystem: bool, podfilePath: string, projectOrWorkspacePath: string, provisioningProfileEncoded: string, provisioningProfileFileId: string, provisioningProfileFilename: string, provisioningProfileUploadId: string, scheme: string, targetToArchive: string, teamId: string, xcodeProjectSha: string, xcodeVersion: string>>, trigger: string, id: int>
# operationId: branchConfigurations_update
export def "branch-configurations-update" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-versioning: record # The versioning configuration for artifacts built for this branch — shape: {buildNumberFormat?: "buildId"|"timestamp"}
  --badge-is-enabled: oneof<nothing, bool>
  --clone-from-branch: string # A configured branch name to clone from. If provided, all other parameters will be ignored. Only supported in POST requests.
  --signed: oneof<nothing, bool>
  --tests-enabled: oneof<nothing, bool>
  --toolsets: any # The branch build configuration for each toolset — shape: {android?: any, javascript?: any, xamarin?: any, xcode?: any}
  --trigger: string@trigger-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    body: {content_type: "application/json", kind: json, fields: [{name: artifactVersioning, var: artifact_versioning}, {name: badgeIsEnabled, var: badge_is_enabled}, {name: cloneFromBranch, var: clone_from_branch}, {name: signed, var: signed}, {name: testsEnabled, var: tests_enabled}, {name: toolsets, var: toolsets}, {name: trigger, var: trigger}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, artifact_versioning: $artifact_versioning, badge_is_enabled: $badge_is_enabled, clone_from_branch: $clone_from_branch, signed: $signed, tests_enabled: $tests_enabled, toolsets: $toolsets, trigger: $trigger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the build configuration in Azure pipeline YAML format
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/export_config
# Returns: record<yaml: string>
# operationId: buildConfigurations_get
export def "build-configurations-get" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Configuration format (default: yaml)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/export_config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    query: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the projects in the repository for the branch, for all toolsets
#
# GET /v0.1/apps/{owner_name}/{app_name}/branches/{branch}/toolset_projects
# Returns: record<android: record<androidModules: list<record>, gradleWrapperPath: string>, buildscripts: any, commit: string, javascript: record<javascriptSolutions: list<record>, packageJsonPaths: list<string>>, testcloud: record<projects: list<record>>, uwp: record<uwpSolutions: list<record>>, xamarin: record<xamarinSolutions: list<record>>, xcode: record<xcodeSchemeContainers: list<record>>>
# operationId: builds_listToolsetProjects
export def "builds-list-toolset-projects" [
  owner_name: string
  app_name: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --os: string@os-completer-1 # The desired OS for the project scan; normally the same as the app OS (required)
  --platform: string@platform-completer-1 # The desired platform for the project scan (required)
  --max-search-depth: int # The depth of the repository to search for project files
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/branches/{branch}/toolset_projects"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: branch, var: branch}]
    query: [{name: os, var: os, required: true}, {name: platform, var: platform, required: true}, {name: maxSearchDepth, var: max_search_depth}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, branch: $branch, os: $os, platform: $platform, max_search_depth: $max_search_depth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get bug tracker settings for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/bugtracker
# Returns: record<event_types: list<string>, settings: record<callback_url: string, owner_name: string, type: string>, state: string, token_id: string, type: string>
# operationId: bugtracker_getSettings
export def "bugtracker-get-settings" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/bugtracker"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project issue related to a crash group
#
# GET /v0.1/apps/{owner_name}/{app_name}/bugtracker/crashGroup/{crash_group_id}
# Returns: record<bug_tracker_type: string, event_type: string, id: string, mobile_center_id: string, repo_name: string, title: string, url: string>
# operationId: bugTracker_getRepoIssueFromCrash
export def "bug-tracker-get-repo-issue-from-crash" [
  owner_name: string
  app_name: string
  crash_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/bugtracker/crashGroup/{crash_group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Application specific build service status
#
# GET /v0.1/apps/{owner_name}/{app_name}/build_service_status
# Returns: record<message: string, os: string, service: string, status: string, url: string, valid_until: int>
# operationId: builds_getStatusByAppId
export def "builds-get-status-by-app-id" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/build_service_status"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the build detail for the given build ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}
# Returns: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>
# operationId: builds_get
export def "builds-get" [
  owner_name: string
  app_name: string
  build_id: int
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
    path: "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a build
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}
# Returns: record<buildNumber: string, finishTime: string, id: int, lastChangedDate: string, queueTime: string, result: string, sourceBranch: string, sourceVersion: string, startTime: string, status: string>
# operationId: builds_update
export def "builds-update" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # The build status; used to cancel builds
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: build_id, var: build_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_id: $build_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Distribute a build
#
# POST /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/distribute
# Returns: record<status: string, upload_id: string>
# operationId: builds_distribute
export def "builds-distribute" [
  owner_name: string
  app_name: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destinations: list # Array of objects {id:string, type:string} with "id" being the distribution group ID, store ID, or tester email, and "type" being "group", "store", or "tester" — item shape: {id: string, type: "store"|"group"|"tester"}
  --mandatory-update: oneof<nothing, bool>
  --notify-testers: oneof<nothing, bool> # default: true
  --release-notes: string # The release notes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/distribute"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: build_id, var: build_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinations, var: destinations}, {name: mandatoryUpdate, var: mandatory_update}, {name: notifyTesters, var: notify_testers}, {name: releaseNotes, var: release_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_id: $build_id, destinations: $destinations, mandatory_update: $mandatory_update, notify_testers: $notify_testers, release_notes: $release_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the download URI
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/downloads/{download_type}
# Returns: record<uri: string>
# operationId: builds_getDownloadUri
export def "builds-get-download-uri" [
  owner_name: string
  app_name: string
  build_id: int
  download_type: string@download-type-completer
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
    path: "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/downloads/{download_type}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: build_id, var: build_id}, {name: download_type, var: download_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_id: $build_id, download_type: $download_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the build log
#
# GET /v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/logs
# Returns: record<value: list<string>>
# operationId: builds_getLog
export def "builds-get-log" [
  owner_name: string
  app_name: string
  build_id: int
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
    path: "/v0.1/apps/{owner_name}/{app_name}/builds/{build_id}/logs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns commit information for a batch of shas
#
# GET /v0.1/apps/{owner_name}/{app_name}/commits/batch
# Returns: table<sha: string, url: string, commit: record<author: record, message: string>>
# operationId: commits_listByShaList
export def "commits-list-by-sha-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hashes: list<string> # A collection of commit SHAs comma-delimited (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/commits/batch"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: hashes, var: hashes, style: csv, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, hashes: $hashes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of crash groups and whether the list contains all available groups.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups
# DEPRECATED
# Returns: record<continuation_token: string, crash_groups: table<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record, status: string>, limited_result_set: bool>
# operationId: crashGroups_list
@deprecated
export def "crash-groups-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-occurrence-from: string # Earliest date when the last time a crash occured in a crash group (format: date-time)
  --last-occurrence-to: string # Latest date when the last time a crash occured in a crash group (format: date-time)
  --app-version: string # version
  --group-type: string@group-type-completer
  --group-status: string@group-status-completer
  --group-text-search: string # A freetext search that matches in crash, crash types, crash stack_traces and crash user
  --orderby: string@orderby-completer # the OData-like $orderby argument (default: last_occurrence desc, allows empty value)
  --continuation-token: string # Cassandra request continuation token. The token is used for pagination.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: last_occurrence_from, var: last_occurrence_from}, {name: last_occurrence_to, var: last_occurrence_to}, {name: app_version, var: app_version}, {name: group_type, var: group_type}, {name: group_status, var: group_status}, {name: group_text_search, var: group_text_search}, {name: "$orderby", var: orderby}, {name: continuation_token, var: continuation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, last_occurrence_from: $last_occurrence_from, last_occurrence_to: $last_occurrence_to, app_version: $app_version, group_type: $group_type, group_status: $group_status, group_text_search: $group_text_search, orderby: $orderby, continuation_token: $continuation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}
# DEPRECATED
# Returns: record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string>
# operationId: crashGroups_get
@deprecated
export def "crash-groups-get" [
  owner_name: string
  app_name: string
  crash_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a group.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}
# DEPRECATED
# Returns: record<annotation: string, app_version: string, build: string, count: int, crash_group_id: string, crash_reason: string, display_id: string, exception: string, fatal: bool, first_occurrence: string, impacted_users: int, last_occurrence: string, new_crash_group_id: string, reason_frame: record<app_code: bool, class_method: bool, class_name: string, code_formatted: string, code_raw: string, exception_type: string, file: string, framework_name: string, language: string, line: int, method: string, method_params: string, os_exception_type: string>, status: string>
# operationId: crashGroups_update
@deprecated
export def "crash-groups-update" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotation: string
  --status: any@status-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotation, var: annotation}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, annotation: $annotation, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all crashes of a group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes
# DEPRECATED
# Returns: table<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record, reason: string, threads: list, title: string>, timestamp: string, user_email: string, user_name: string, version: string>
# operationId: crashes_list
@deprecated
export def "crashes-list" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-report: oneof<nothing, bool> # true if the crash should include the raw crash report. Default is false (default: false)
  --include-log: oneof<nothing, bool> # true if the crash should include the custom log report. Default is false (default: false)
  --date-from: string # format: date-time
  --date-to: string # format: date-time
  --app-version: string # version
  --error-type: string@error-type-completer
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: include_report, var: include_report}, {name: include_log, var: include_log}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: app_version, var: app_version}, {name: error_type, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, include_report: $include_report, include_log: $include_log, date_from: $date_from, date_to: $date_to, app_version: $app_version, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific crash and related attachments and blobs for an app.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}
# DEPRECATED
# Returns: record<app_id: string, attachments_deleted: int, blobs_failed: int, blobs_succeeded: int, crash_group_id: string, crash_id: string, crashes_deleted: int>
# operationId: crashes_delete
@deprecated
export def "crashes-delete" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --retention-delete: oneof<nothing, bool> # true in that case if the method should skip update counts (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    query: [{name: retention_delete, var: retention_delete}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id, retention_delete: $retention_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific crash for an app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}
# DEPRECATED
# Returns: record<build: string, crash_id: string, details: record<app_start_timestamp: string, carrier_country: string, carrier_name: string, locale: string, os_build: string, rooted: bool, screen_size: string>, device: string, device_name: string, display_id: string, new_crash_group_id: string, new_crash_id: string, os_type: string, os_version: string, stacktrace: record<exception: record<frames: list, inner_exceptions: list, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: list<record>, title: string>, timestamp: string, user_email: string, user_name: string, version: string>
# operationId: crashes_get
@deprecated
export def "crashes-get" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-report: oneof<nothing, bool> # true if the crash should include the raw crash report. Default is false (default: false)
  --include-log: oneof<nothing, bool> # true if the crash should include the custom log report. Default is false (default: false)
  --include-details: oneof<nothing, bool> # true if the crash should include in depth crash details (default: false)
  --include-stacktrace: oneof<nothing, bool> # true if the crash should include the stacktrace information (default: false)
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    query: [{name: include_report, var: include_report}, {name: include_log, var: include_log}, {name: include_details, var: include_details}, {name: include_stacktrace, var: include_stacktrace}, {name: grouping_only, var: grouping_only}]
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id, include_report: $include_report, include_log: $include_log, include_details: $include_details, include_stacktrace: $include_stacktrace, grouping_only: $grouping_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the native log of a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native
# DEPRECATED
# Returns: string
# operationId: crashes_getNativeCrash
@deprecated
export def "crashes-get-native-crash" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the native log of a specific crash as a text attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native/download
# DEPRECATED
# Returns: string
# operationId: crashes_getNativeCrashDownload
@deprecated
export def "crashes-get-native-crash-download" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/native/download"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the URI location to download json of a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/raw/location
# DEPRECATED
# Returns: record<uri: string>
# operationId: crashes_getRawCrashLocation
@deprecated
export def "crashes-get-raw-crash-location" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/raw/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a stacktrace for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/stacktrace
# DEPRECATED
# Returns: record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>
# operationId: crashes_getStacktrace
@deprecated
export def "crashes-get-stacktrace" [
  owner_name: string
  app_name: string
  crash_group_id: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/crashes/{crash_id}/stacktrace"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}, {name: crash_id, var: crash_id}]
    query: [{name: grouping_only, var: grouping_only}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, crash_id: $crash_id, grouping_only: $grouping_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a stacktrace for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/stacktrace
# DEPRECATED
# Returns: record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>
# operationId: crashGroups_getStacktrace
@deprecated
export def "crash-groups-get-stacktrace" [
  owner_name: string
  app_name: string
  crash_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grouping-only: oneof<nothing, bool> # true if the stacktrace should be only the relevant thread / exception. Default is false (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crash_groups/{crash_group_id}/stacktrace"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_group_id, var: crash_group_id}]
    query: [{name: grouping_only, var: grouping_only}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_group_id: $crash_group_id, grouping_only: $grouping_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all attachments for a specific crash.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments
# DEPRECATED
# Returns: table<app_id: string, attachment_id: string, blob_location: string, content_type: string, crash_id: string, created_time: string, file_name: string, size: float>
# operationId: crashes_listAttachments
@deprecated
export def "crashes-list-attachments" [
  owner_name: string
  app_name: string
  crash_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_id, var: crash_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_id: $crash_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the URI location to download crash attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/location
# DEPRECATED
# Returns: record<uri: string>
# operationId: crashes_getCrashAttachmentLocation
@deprecated
export def "crashes-get-crash-attachment-location" [
  owner_name: string
  app_name: string
  crash_id: string
  attachment_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_id, var: crash_id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_id: $crash_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets content of the text attachment.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/text
# DEPRECATED
# Returns: string
# operationId: crashes_getCrashTextAttachmentContent
@deprecated
export def "crashes-get-crash-text-attachment-content" [
  owner_name: string
  app_name: string
  crash_id: string
  attachment_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/attachments/{attachment_id}/text"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_id, var: crash_id}, {name: attachment_id, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_id: $crash_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session logs by crash ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/session_logs
# Returns: record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<account_id: string, auth_provider: string, device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>
# operationId: Crashes_ListSessionLogs
export def "crashes-list-session-logs" [
  owner_name: string
  app_name: string
  crash_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of data requested (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/crashes/{crash_id}/session_logs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: crash_id, var: crash_id}]
    query: [{name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, crash_id: $crash_id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets whether the application has any crashes.
#
# GET /v0.1/apps/{owner_name}/{app_name}/crashes_info
# DEPRECATED
# Returns: record<features: record<crash_download_raw: bool, crashgroup_analytics_crashfreeusers: bool, crashgroup_analytics_impactedusers: bool, crashgroup_modify_annotation: bool, crashgroup_modify_status: bool, search: bool>, has_crashes: bool>
# operationId: crashes_getAppCrashesInfo
@deprecated
export def "crashes-get-app-crashes-info" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/crashes_info"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of CodePush deployments for the given app
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments
# Returns: table<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>
# operationId: codePushDeployments_list
export def "code-push-deployments-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a CodePush Deployment for the given app
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments
# Returns: record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>
# operationId: codePushDeployments_create
export def "code-push-deployments-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --latest-release: any # shape: {description?: string, is_disabled?: bool, is_mandatory?: bool, rollout?: int, target_binary_range?: string, blob_url?: string, diff_package_map?: record, label?: string, original_deployment?: string, original_label?: string, package_hash?: string, release_method?: "Upload"|"Promote"|"Rollback", released_by?: string, size?: float, upload_time?: int}
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: latest_release, var: latest_release}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, key: $key, latest_release: $latest_release, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a CodePush Deployment for the given app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# operationId: codePushDeployments_delete
export def "code-push-deployments-delete" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a CodePush Deployment for the given app
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# Returns: record<key: string, latest_release: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>, name: string>
# operationId: codePushDeployments_get
export def "code-push-deployments-get" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a CodePush Deployment for the given app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}
# operationId: codePushDeployments_update
export def "code-push-deployments-update" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all releases metrics for specified Deployment
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/metrics
# Returns: table<active: int, downloaded: int, failed: int, installed: int, label: string>
# operationId: codePushDeploymentMetrics_get
export def "code-push-deployment-metrics-get" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/metrics"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promote one release (default latest one) from one deployment to another
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/promote_release/{promote_deployment_name}
# Returns: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>
# operationId: codePushDeployments_promote
export def "code-push-deployments-promote" [
  owner_name: string
  app_name: string
  deployment_name: string
  promote_deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-disabled: oneof<nothing, bool>
  --is-mandatory: oneof<nothing, bool>
  --rollout: int
  --target-binary-range: string
  --label: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/promote_release/{promote_deployment_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}, {name: promote_deployment_name, var: promote_deployment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: is_disabled, var: is_disabled}, {name: is_mandatory, var: is_mandatory}, {name: rollout, var: rollout}, {name: target_binary_range, var: target_binary_range}, {name: label, var: label}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, promote_deployment_name: $promote_deployment_name, description: $description, is_disabled: $is_disabled, is_mandatory: $is_mandatory, rollout: $rollout, target_binary_range: $target_binary_range, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears a Deployment of releases
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# operationId: codePushDeploymentReleases_delete
export def "code-push-deployment-releases-delete" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the history of releases on a Deployment
#
# GET /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# Returns: table<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>
# operationId: codePushDeploymentReleases_get
export def "code-push-deployment-releases-get" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CodePush release for the specified deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases
# Returns: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>
# operationId: codePushDeploymentReleases_create
export def "code-push-deployment-releases-create" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-deployment-name: string # This specifies which deployment you want to release the update to. Default is Staging. (spec name: deployment_name)
  --description: string # This provides an optional "change log" for the deployment.
  --disabled: oneof<nothing, bool> # This specifies whether an update should be downloadable by end users or not.
  --mandatory: oneof<nothing, bool> # This specifies whether the update should be considered mandatory or not (e.g. it includes a critical security fix).
  --no-duplicate-release-error: oneof<nothing, bool> # This specifies that if the update is identical to the latest release on the deployment, the CLI should generate a warning instead of an error.
  release_upload: any # The upload metadata from the release initialization step. — shape: {id: string, token: string, upload_domain: string}
  --rollout: int # This specifies the percentage of users (as an integer between 1 and 100) that should be eligible to receive this update.
  target_binary_version: string # the binary version of the application
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: deployment_name, var: body_deployment_name}, {name: description, var: description}, {name: disabled, var: disabled}, {name: mandatory, var: mandatory}, {name: no_duplicate_release_error, var: no_duplicate_release_error}, {name: release_upload, var: release_upload}, {name: rollout, var: rollout}, {name: target_binary_version, var: target_binary_version}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, body_deployment_name: $body_deployment_name, description: $description, disabled: $disabled, mandatory: $mandatory, no_duplicate_release_error: $no_duplicate_release_error, release_upload: $release_upload, rollout: $rollout, target_binary_version: $target_binary_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a CodePush release metadata under the given Deployment
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases/{release_label}
# Returns: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>
# operationId: deploymentReleases_update
export def "deployment-releases-update" [
  owner_name: string
  app_name: string
  deployment_name: string
  release_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-disabled: oneof<nothing, bool>
  --is-mandatory: oneof<nothing, bool>
  --rollout: int
  --target-binary-range: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/releases/{release_label}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}, {name: release_label, var: release_label}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: is_disabled, var: is_disabled}, {name: is_mandatory, var: is_mandatory}, {name: rollout, var: rollout}, {name: target_binary_range, var: target_binary_range}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, release_label: $release_label, description: $description, is_disabled: $is_disabled, is_mandatory: $is_mandatory, rollout: $rollout, target_binary_range: $target_binary_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rollback the latest or a specific release for an app deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/rollback_release
# Returns: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, blob_url: string, diff_package_map: record, label: string, original_deployment: string, original_label: string, package_hash: string, release_method: string, released_by: string, size: float, upload_time: int>
# operationId: codePushDeploymentRelease_rollback
export def "code-push-deployment-release-rollback" [
  owner_name: string
  app_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/rollback_release"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CodePush release upload for the specified deployment
#
# POST /v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/uploads
# Returns: record<id: string, token: string, upload_domain: string>
# operationId: codePushDeploymentUpload_create
export def "code-push-deployment-upload-create" [
  owner_name: string
  app_name: string
  deployment_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/deployments/{deployment_name}/uploads"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: deployment_name, var: deployment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, deployment_name: $deployment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of available devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/device_configurations
# Returns: table<id: string, image: record<full: string, thumb: string>, marketShare: float, model: record<availabilityCount: float, cpu: record, deviceFrame: record, dimensions: record, formFactor: string, manufacturer: string, memory: record, model: string, name: string, platform: string, releaseDate: string, resolution: record, screenRotation: float, screenSize: record>, name: string, os: string, osName: string, tier: float>
# operationId: test_getDeviceConfigurations
export def "test-get-device-configurations" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-upload-id: string # The ID of the test run (format: uuid)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/device_configurations"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: app_upload_id, var: app_upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, app_upload_id: $app_upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a short ID for a list of devices
#
# POST /v0.1/apps/{owner_name}/{app_name}/device_selection
# Returns: record<shortId: string>
# operationId: test_createDeviceSelection
export def "test-create-device-selection" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/device_selection"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, devices: $devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Warning, this operation is not reversible.** A successful call to this API will permanently stop ingesting any logs received via SDK by app_id, and cannot be restored. We advise caution when using this API, it is designed to permanently disable an app_id.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/devices/block_logs
# Returns: string
# operationId: App_BlockLogs
export def "app-block-logs" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/devices/block_logs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# **Warning, this operation is not reversible.** A successful call to this API will permanently stop ingesting any logs received via SDK for the given installation ID, and cannot be restored. We advise caution when using this API, it is designed to permanently disable collection from a specific installation of the app on a device, usually following the request from a user.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/devices/block_logs/{install_id}
# Returns: string
# operationId: Devices_BlockLogs
export def "devices-block-logs" [
  owner_name: string
  app_name: string
  install_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/devices/block_logs/{install_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: install_id, var: install_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, install_id: $install_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets top N (ordered by crash count) of crash groups by missing symbol
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups
# Returns: record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int>
# operationId: missingSymbolGroups_list
export def "missing-symbol-groups-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # top N elements (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: top, var: top, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets missing symbol crash group by its id
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups/{symbol_group_id}
# Returns: record<groups: table<app_build: string, app_id: string, app_ver: string, crash_count: int, error_count: int, last_modified: string, missing_symbols: list, status: string, symbol_group_id: string>, total_crash_count: int>
# operationId: missingSymbolGroups_get
export def "missing-symbol-groups-get" [
  owner_name: string
  app_name: string
  symbol_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups/{symbol_group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_group_id, var: symbol_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_group_id: $symbol_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets application level statistics for all missing symbol groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups_info
# Returns: record<total_crash_count: int>
# operationId: missingSymbolGroups_info
export def "missing-symbol-groups-info" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/diagnostics/symbol_groups_info"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of distribution groups in the app specified
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups
# Returns: table<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_list
export def "distribution-groups-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new distribution group and returns it to the caller
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_create
export def "distribution-groups-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the distribution group. If not specified, the name will be used.
  name: string # The name of the distribution group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a distribution group
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_delete
export def "distribution-groups-delete" [
  owner_name: string
  app_name: string
  distribution_group_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single distribution group for a given distribution group name
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_get
export def "distribution-groups-get" [
  owner_name: string
  app_name: string
  distribution_group_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the attributes of distribution group
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_update
export def "distribution-groups-update" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-public: oneof<nothing, bool> # Whether the distribution group is public
  --name: string # The name of the distribution group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_public, var: is_public}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, is_public: $is_public, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all devices associated with the given distribution group
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices
# Returns: table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>
# operationId: devices_list
export def "devices-list" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --release-id: float # when provided, gets the provisioning state of the devices owned by users of this distribution group when compared to the provided release.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    query: [{name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all devices associated with the given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices/download_devices_list
# operationId: devices_listCsvFormat
export def "devices-list-csv-format" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unprovisioned-only: oneof<nothing, bool> # when true, filters out provisioned devices (default: false)
  --udids: list<string> # multiple UDIDs which should be part of the resulting CSV.
]: nothing -> any {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/devices/download_devices_list"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    query: [{name: unprovisioned_only, var: unprovisioned_only}, {name: udids, var: udids, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, unprovisioned_only: $unprovisioned_only, udids: $udids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of member details in the distribution group specified
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members
# Returns: table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string>
# operationId: distributionGroups_listUsers
export def "distribution-groups-list-users" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-pending-invitations: oneof<nothing, bool> # Whether to exclude pending invitations in the response
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    query: [{name: exclude_pending_invitations, var: exclude_pending_invitations}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, exclude_pending_invitations: $exclude_pending_invitations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the members to the specified distribution group
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members
# Returns: table<code: string, invite_pending: bool, message: string, status: int, user_email: string>
# operationId: distributionGroups_addUser
export def "distribution-groups-add-user" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the users from the distribution group
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members/bulk_delete
# Returns: table<code: string, message: int, status: int, user_email: string>
# operationId: distributionGroups_removeUser
export def "distribution-groups-remove-user" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/members/bulk_delete"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return basic information about distributed releases in a given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases
# Returns: table<enabled: bool, id: int, is_external_build: bool, mandatory_update: bool, origin: string, short_version: string, uploaded_at: string, version: string>
# operationId: releases_listByDistributionGroup
export def "releases-list-by-distribution-group" [
  owner_name: string
  app_name: string
  distribution_group_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a release with id 'release_id' in a given distribution group.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}
# operationId: releases_deleteWithDistributionGroupId
export def "releases-delete-with-distribution-group-id" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  release_id: int
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return detailed information about a distributed release in a given distribution group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestByDistributionGroup
export def "releases-get-latest-by-distribution-group" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}, {name: release_id, var: release_id}]
    query: [{name: is_install_page, var: is_install_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, release_id: $release_id, is_install_page: $is_install_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend distribution group app invite notification to previously invited testers
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/resend_invite
# operationId: distributionGroups_resendInvite
export def "distribution-groups-resend-invite" [
  owner_name: string
  app_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_groups/{distribution_group_name}/resend_invite"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the store details from Storage store table for a particular application.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores
# Returns: table<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record, target_audience: record>, name: string, service_connection_id: string, track: string, type: string>
# operationId: stores_list
export def "stores-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new external store for the specified application.
#
# POST /v0.1/apps/{owner_name}/{app_name}/distribution_stores
# Returns: record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string>
# operationId: stores_create
export def "stores-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --intune-details: any # shape: {app_category?: any, secret_json?: any, target_audience?: any, tenant_id?: string}
  --name: string # name of the store. In case of googleplay, and Apple store this is fixed to Production.
  --service-connection-id: string # Id for the shared service connection. In case of Apple AppStore, this connection will be used to create and connect to the Apple AppStore in Mobile Center.
  --track: string@track-completer # track of the store. Can be production, alpha & beta for googleplay. Can be production, testflight-internal & testflight-external for Apple Store.
  --type: string@type-completer # store Type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: intune_details, var: intune_details}, {name: name, var: name}, {name: service_connection_id, var: service_connection_id}, {name: track, var: track}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, intune_details: $intune_details, name: $name, service_connection_id: $service_connection_id, track: $track, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the store based on specific store name.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# operationId: stores_delete
export def "stores-delete" [
  owner_name: string
  app_name: string
  store_name: string
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
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the store details for specified store name.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# Returns: record<created_by: string, created_by_principal_type: string, id: string, intune_details: record<app_category: record<id: string, name: string>, target_audience: record<id: string, name: string>>, name: string, service_connection_id: string, track: string, type: string>
# operationId: stores_get
export def "stores-get" [
  owner_name: string
  app_name: string
  store_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the store.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}
# operationId: stores_patch
export def "stores-patch" [
  owner_name: string
  app_name: string
  store_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  service_connection_id: string # Service connection id to updated.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: service_connection_id, var: service_connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, service_connection_id: $service_connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the latest release published in a store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/latest_release
# Returns: table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string>
# operationId: storeReleases_getLatest
export def "store-releases-get-latest" [
  owner_name: string
  app_name: string
  store_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/latest_release"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return all releases published in a store
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases
# Returns: table<destination_type: string, distribution_stores: list<record>, id: float, short_version: string, uploaded_at: string, version: string>
# operationId: storeReleases_list
export def "store-releases-list" [
  owner_name: string
  app_name: string
  store_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the release with release Id
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}
# operationId: storeReleases_delete
export def "store-releases-delete" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
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
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}, {name: release_id, var: release_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, release_id: $release_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return releases published in a store for releaseId and storeId
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}
# Returns: table<android_min_api_level: string, app_display_name: string, app_name: string, bundle_identifier: string, distribution_stores: list<record>, download_url: string, fingerprint: string, id: float, install_url: string, min_os: string, release_notes: string, short_version: string, size: float, status: string, uploaded_at: string, version: string>
# operationId: storeReleases_get
export def "store-releases-get" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the Error Details of release which failed in publishing.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_error_details
# Returns: record<is_log_available: bool, message: string>
# operationId: storeReleases_getPublishError
export def "store-releases-get-publish-error" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: float
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_error_details"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publish logs for a particular release published to a particular store
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_logs
# operationId: storeReleasePublishLogs_get
export def "store-release-publish-logs-get" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/publish_logs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the Real time Status publishing of release from store.
#
# GET /v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/realtimestatus
# Returns: record<app_id: string, release_id: string, status: record<status: string, storetype: string, track: string, version: string>>
# operationId: storeReleases_getRealTimeStatusByReleaseId
export def "store-releases-get-real-time-status-by-release-id" [
  owner_name: string
  app_name: string
  store_name: string
  release_id: float
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
    path: "/v0.1/apps/{owner_name}/{app_name}/distribution_stores/{store_name}/releases/{release_id}/realtimestatus"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: store_name, var: store_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, store_name: $store_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of app builds
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/availableAppBuilds
# Returns: record<appBuilds: list<string>>
# operationId: Errors_AppBuildsList
export def "errors-app-builds-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # required
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/availableAppBuilds"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: version, var: version, required: true}, {name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: errorType, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, version: $version, start: $start, end: $end, top: $top, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all available versions in the time range.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/available_versions
# Returns: record<total_count: int, versions: list<string>>
# operationId: Errors_AvailableVersions
export def "errors-available-versions" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
  --filter: string # A filter as specified in https://github.com/Microsoft/api-guidelines/blob/master/Guidelines.md#97-filtering. (format: string)
  --inlinecount: string@inlinecount-completer # Controls whether or not to include a count of all the items across all pages. (default: none)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/available_versions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: "$skip", var: skip}, {name: "$filter", var: filter}, {name: "$inlinecount", var: inlinecount}, {name: errorType, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, top: $top, skip: $skip, filter: $filter, inlinecount: $inlinecount, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of crashes or errors by day in the time range based the selected versions. If SingleErrorTypeParameter is not provided, defaults to handlederror.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorCountsPerDay
# Returns: record<count: int, errors: table<count: int, datetime: string>>
# operationId: Errors_CountsPerDay
export def "errors-counts-per-day" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --app-build: string # app build (format: string)
  --error-type: string@error-type-completer-2 # Type of error (handled vs unhandled), excluding All
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorCountsPerDay"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: version, var: version}, {name: start, var: start, required: true}, {name: end, var: end}, {name: app_build, var: app_build}, {name: errorType, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, version: $version, start: $start, end: $end, app_build: $app_build, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of error groups
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups
# Returns: record<errorGroups: table<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: list, annotation: string, state: string>, nextLink: string>
# operationId: Errors_GroupList
export def "errors-group-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --app-build: string # app build (format: string)
  --group-state: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --orderby: string # controls the sorting order and sorting based on which column (default: count desc)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --error-type: string@error-type-completer-1 # Type of error (handled vs unhandled), including All
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: version, var: version}, {name: app_build, var: app_build}, {name: groupState, var: group_state}, {name: start, var: start, required: true}, {name: end, var: end}, {name: "$orderby", var: orderby}, {name: "$top", var: top}, {name: errorType, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, version: $version, app_build: $app_build, group_state: $group_state, start: $start, end: $end, orderby: $orderby, top: $top, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error groups list based on search parameters
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/search
# Returns: record<errorGroups: table<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: list, annotation: string, state: string>, hasMoreResults: bool>
# operationId: Errors_ErrorGroupsSearch
export def "errors-error-groups-search" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter as specified in OData notation (format: string)
  --q: string # A query string (format: string)
  --order: string@order-completer # It controls the order of sorting (default: desc)
  --sort: string@sort-completer # It controls the sort based on specified field (default: matchingReportsCount)
  --top: int # The maximum number of results to return (format: int64, default: 100)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/search"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: filter, var: filter}, {name: q, var: q}, {name: order, var: order}, {name: sort, var: sort}, {name: "$top", var: top}, {name: "$skip", var: skip}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, filter: $filter, q: $q, order: $order, sort: $sort, top: $top, skip: $skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error group details
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}
# Returns: record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, annotation: string, state: string>
# operationId: Errors_GroupDetails
export def "errors-group-details" [
  owner_name: string
  app_name: string
  error_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update error group state
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}
# Returns: record<appBuild: string, appVersion: string, codeRaw: string, count: int, deviceCount: int, errorGroupId: string, exceptionAppCode: bool, exceptionClassMethod: bool, exceptionClassName: string, exceptionFile: string, exceptionLine: string, exceptionMessage: string, exceptionMethod: string, exceptionType: string, firstOccurrence: string, hidden: bool, lastOccurrence: string, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, annotation: string, state: string>
# operationId: Errors_UpdateState
export def "errors-update-state" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotation: string
  state: string@state-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotation, var: annotation}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, annotation: $annotation, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count of errors by day in the time range of the selected error group with selected version
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorCountsPerDay
# Returns: record<count: int, errors: table<count: int, datetime: string>>
# operationId: Errors_GroupCountsPerDay
export def "errors-group-counts-per-day" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # format: string
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorCountsPerDay"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    query: [{name: version, var: version}, {name: start, var: start, required: true}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, version: $version, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Percentage of error-free devices by day in the time range. Api will return -1 if crash devices is greater than active devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorfreeDevicePercentages
# Returns: record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>>
# operationId: Errors_GroupErrorFreeDevicePercentages
export def "errors-group-error-free-device-percentages" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errorfreeDevicePercentages"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all errors for group
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors
# Returns: record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, nextLink: string>
# operationId: Errors_ListForGroup
export def "errors-list-for-group" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
  --model: string # format: string
  --os: string # format: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: "$top", var: top}, {name: model, var: model}, {name: os, var: os}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, start: $start, end: $end, top: $top, model: $model, os: $os
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Latest error details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/latest
# Returns: record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>
# operationId: Errors_LatestErrorDetails
export def "errors-latest-error-details" [
  owner_name: string
  app_name: string
  error_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/latest"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific error and related attachments and blobs for an app. Searchable data will not be deleted immediately and may take up to 30 days.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}
# Returns: record<appId: string, attachmentsDeleted: int, blobsFailed: int, blobsSucceeded: int, errorGroupId: string, errorId: string, errorsDeleted: int>
# operationId: Errors_DeleteError
export def "errors-delete-error" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}, {name: errorId, var: error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, error_id: $error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}
# Returns: record<appLaunchTimestamp: string, carrierName: string, jailbreak: bool, name: string, properties: record, reasonFrames: table<appCode: bool, classMethod: bool, className: string, codeFormatted: string, codeRaw: string, exceptionType: string, file: string, frameworkName: string, language: string, line: int, method: string, methodParams: string, osExceptionType: string>, country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>
# operationId: Errors_GetErrorDetails
export def "errors-get-error-details" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}, {name: errorId, var: error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, error_id: $error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download details for a specific error.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/download
# Returns: binary
# operationId: Errors_ErrorDownload
export def "errors-error-download" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # the format of the crash log
]: nothing -> any {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/download"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}, {name: errorId, var: error_id}]
    query: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, error_id: $error_id, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error location.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/location
# Returns: record<uri: string>
# operationId: Errors_ErrorLocation
export def "errors-error-location" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}, {name: errorId, var: error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, error_id: $error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error Stacktrace details.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/stacktrace
# Returns: record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>
# operationId: Errors_ErrorStackTrace
export def "errors-error-stack-trace" [
  owner_name: string
  app_name: string
  error_group_id: string
  error_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/errors/{errorId}/stacktrace"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}, {name: errorId, var: error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, error_id: $error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top models of the selected error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/models
# Returns: record<errorCount: int, models: table<errorCount: int, modelCode: string, modelName: string>>
# operationId: Errors_GroupModelCounts
export def "errors-group-model-counts" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/models"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    query: [{name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top OSes of the selected error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/operatingSystems
# Returns: record<errorCount: int, operatingSystems: table<errorCount: int, operatingSystemName: string>>
# operationId: Errors_GroupOperatingSystemCounts
export def "errors-group-operating-system-counts" [
  owner_name: string
  app_name: string
  error_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (0 will fetch all results till the max number.) (format: int64, default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/operatingSystems"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    query: [{name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the stack trace for the error group.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/stacktrace
# Returns: record<exception: record<frames: list<record>, inner_exceptions: list<any>, platform: string, reason: string, relevant: bool, type: string>, reason: string, threads: table<crashed: bool, exception: record, frames: list, platform: string, relevant: bool, title: string>, title: string>
# operationId: Errors_GroupErrorStackTrace
export def "errors-group-error-stack-trace" [
  owner_name: string
  app_name: string
  error_group_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorGroups/{errorGroupId}/stacktrace"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorGroupId, var: error_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_group_id: $error_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Percentage of error-free devices by day in the time range based on the selected versions. If SingleErrorTypeParameter is not provided, defaults to handlederror. API will return -1 if crash devices is greater than active devices
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/errorfreeDevicePercentages
# Returns: record<averagePercentage: float, dailyPercentages: table<datetime: string, percentage: float>>
# operationId: Errors_ErrorFreeDevicePercentages
export def "errors-error-free-device-percentages" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date time in data in ISO 8601 date time format (required, format: date-time)
  --end: string # Last date time in data in ISO 8601 date time format (format: date-time)
  --versions: list<string>
  --app-build: string # app build (format: string)
  --error-type: string@error-type-completer-2 # Type of error (handled vs unhandled), excluding All
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/errorfreeDevicePercentages"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: start, var: start, required: true}, {name: end, var: end}, {name: versions, var: versions, style: pipes}, {name: app_build, var: app_build}, {name: errorType, var: error_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, start: $start, end: $end, versions: $versions, app_build: $app_build, error_type: $error_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# gets the retention settings in days
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/retention_settings
# Returns: record<retention_in_days: int>
# operationId: errors_getRetentionSettings
export def "errors-get-retention-settings" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/retention_settings"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Errors list based on search parameters
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/search
# Returns: record<errors: table<country: string, deviceName: string, errorId: string, hasAttachments: bool, hasBreadcrumbs: bool, language: string, osType: string, osVersion: string, timestamp: string, userId: string>, hasMoreResults: bool>
# operationId: Errors_ErrorSearch
export def "errors-error-search" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter as specified in OData notation (format: string)
  --q: string # A query string (format: string)
  --order: string@order-completer # It controls the order of sorting (default: desc)
  --sort: string@sort-completer-1 # It controls the sort based on specified field (default: timestamp)
  --top: int # The maximum number of results to return (format: int64, default: 100)
  --skip: int # The offset (starting at 0) of the first result to return. This parameter along with limit is used to perform pagination. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/search"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: filter, var: filter}, {name: q, var: q}, {name: order, var: order}, {name: sort, var: sort}, {name: "$top", var: top}, {name: "$skip", var: skip}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, filter: $filter, q: $q, order: $order, sort: $sort, top: $top, skip: $skip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List error attachments.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments
# Returns: table<appId: string, attachmentId: string, blobLocation: string, contentType: string, crashId: string, createdTime: string, fileName: string, size: int>
# operationId: Errors_ErrorAttachments
export def "errors-error-attachments" [
  owner_name: string
  app_name: string
  error_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorId, var: error_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_id: $error_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error attachment location.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/location
# Returns: record<uri: string>
# operationId: Errors_ErrorAttachmentLocation
export def "errors-error-attachment-location" [
  owner_name: string
  app_name: string
  error_id: string
  attachment_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorId, var: error_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_id: $error_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Error attachment text.
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/text
# Returns: record<content: string>
# operationId: Errors_ErrorAttachmentText
export def "errors-error-attachment-text" [
  owner_name: string
  app_name: string
  error_id: string
  attachment_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/attachments/{attachmentId}/text"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorId, var: error_id}, {name: attachmentId, var: attachment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_id: $error_id, attachment_id: $attachment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session logs by error ID
#
# GET /v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/sessionLogs
# Returns: record<exceeded_max_limit: bool, last_received_log_timestamp: string, logs: table<device: record, event_id: string, event_name: string, install_id: string, message_id: string, properties: record, session_id: string, timestamp: string, type: string>>
# operationId: Errors_ListSessionLogs
export def "errors-list-session-logs" [
  owner_name: string
  app_name: string
  error_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of data requested (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/errors/{errorId}/sessionLogs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: errorId, var: error_id}]
    query: [{name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, error_id: $error_id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List export configurations.
#
# GET /v0.1/apps/{owner_name}/{app_name}/export_configurations
# Returns: record<nextLink: string, total: int, values: table<creation_time: string, export_configuration: record, export_entities: list, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>>
# operationId: ExportConfigurations_List
export def "export-configurations-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new export configuration
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations
# Discriminator (request): type
# Returns: record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>
# operationId: ExportConfigurations_Create
export def "export-configurations-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backfill: oneof<nothing, bool> # Field to determine if backfilling should occur. The default value is true. If set to false export starts from date and time of config creation.
  --export-entities: list<string>
  --resource-group: string # The resource group name on azure
  --resource-name: string # The resource name on azure
  type: string@type-completer-1 # Type of export configuration
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: backfill, var: backfill}, {name: export_entities, var: export_entities}, {name: resource_group, var: resource_group}, {name: resource_name, var: resource_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, backfill: $backfill, export_entities: $export_entities, resource_group: $resource_group, resource_name: $resource_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete export configuration.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# operationId: ExportConfigurations_Delete
export def "export-configurations-delete" [
  owner_name: string
  app_name: string
  export_configuration_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: export_configuration_id, var: export_configuration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, export_configuration_id: $export_configuration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get export configuration.
#
# GET /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# Returns: record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>
# operationId: ExportConfigurations_Get
export def "export-configurations-get" [
  owner_name: string
  app_name: string
  export_configuration_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: export_configuration_id, var: export_configuration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, export_configuration_id: $export_configuration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update export configuration.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}
# Discriminator (request): type
# Returns: record<creation_time: string, export_configuration: record<backfill: bool, export_entities: list<string>, resource_group: string, resource_name: string, type: string>, export_entities: list<string>, export_type: string, id: string, last_run_time: string, resource_group: string, resource_name: string, state: string, state_info: string>
# operationId: ExportConfigurations_PartialUpdate
export def "export-configurations-partial-update" [
  owner_name: string
  app_name: string
  export_configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backfill: oneof<nothing, bool> # Field to determine if backfilling should occur. The default value is true. If set to false export starts from date and time of config creation.
  --export-entities: list<string>
  --resource-group: string # The resource group name on azure
  --resource-name: string # The resource name on azure
  type: string@type-completer-1 # Type of export configuration
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: export_configuration_id, var: export_configuration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: backfill, var: backfill}, {name: export_entities, var: export_entities}, {name: resource_group, var: resource_group}, {name: resource_name, var: resource_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, export_configuration_id: $export_configuration_id, backfill: $backfill, export_entities: $export_entities, resource_group: $resource_group, resource_name: $resource_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable export configuration.
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/disable
# operationId: ExportConfigurations_Disable
export def "export-configurations-disable" [
  owner_name: string
  app_name: string
  export_configuration_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/disable"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: export_configuration_id, var: export_configuration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, export_configuration_id: $export_configuration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable export configuration.
#
# POST /v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/enable
# operationId: ExportConfigurations_Enable
export def "export-configurations-enable" [
  owner_name: string
  app_name: string
  export_configuration_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/export_configurations/{export_configuration_id}/enable"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: export_configuration_id, var: export_configuration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, export_configuration_id: $export_configuration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new asset to upload a file
#
# POST /v0.1/apps/{owner_name}/{app_name}/file_asset
# Returns: record<id: string, location: string, token: string, uploadDomain: string, uploadWindowLocation: string, urlEncodedToken: string>
# operationId: fileAssets_create
export def "file-assets-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/file_asset"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pending invitations for the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/invitations
# Returns: record<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>, app_count: float, distribution_group: record<owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>>, email: string, id: string, invite_type: string, invited_by: record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>, is_existing_user: bool, permissions: list<string>>
# operationId: appInvitations_list
export def "app-invitations-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/invitations"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invites a new or existing user to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/invitations
# operationId: appInvitations_create
export def "app-invitations-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role
  user_email: string # The user's email address
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/invitations"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}, {name: user_email, var: user_email}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, role: $role, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user's invitation to an app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# operationId: appInvitations_delete
export def "app-invitations-delete" [
  owner_name: string
  app_name: string
  user_email: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: user_email, var: user_email}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update pending invitation permission
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# operationId: appInvitations_updatePermissions
export def "app-invitations-update-permissions" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions the user has for the app in the invitation
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: user_email, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, user_email: $user_email, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invites a new or existing user to an app
#
# POST /v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}
# DEPRECATED
# operationId: appInvitations_createByEmail
@deprecated
export def "app-invitations-create-by-email" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The role of the user to be added
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/invitations/{user_email}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: user_email, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, user_email: $user_email, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Email notification settings of user for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/notifications/emailSettings
# Returns: record<request_id: string, eTag: string, enabled: bool, settings: table<default_value: string, event_type: string, value: string>, userId: string, appId: string, user_enabled: bool>
# operationId: notifications_getAppEmailSettings
export def "notifications-get-app-email-settings" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/notifications/emailSettings"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists device sets belonging to the owner
#
# GET /v0.1/apps/{owner_name}/{app_name}/owner/device_sets
# Returns: table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_listDeviceSetsOfOwner
export def "test-list-device-sets-of-owner" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a device set belonging to the owner
#
# POST /v0.1/apps/{owner_name}/{app_name}/owner/device_sets
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_createDeviceSetOfOwner
export def "test-create-device-set-of-owner" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, devices: $devices, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a device set belonging to the owner
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# operationId: test_deleteDeviceSetOfOwner
export def "test-delete-device-set-of-owner" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a device set belonging to the owner
#
# GET /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_getDeviceSetOfOwner
export def "test-get-device-set-of-owner" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a device set belonging to the owner
#
# PUT /v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_updateDeviceSetOfOwner
export def "test-update-device-set-of-owner" [
  owner_name: string
  app_name: string
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
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/owner/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id, devices: $devices, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest release from every distribution group associated with an application.
#
# GET /v0.1/apps/{owner_name}/{app_name}/recent_releases
# Returns: table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>
# operationId: releases_listLatest
export def "releases-list-latest" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/recent_releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return basic information about releases.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases
# Returns: table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>
# operationId: releases_list
export def "releases-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --published-only: oneof<nothing, bool> # When *true*, filters out releases that were uploaded but were never distributed. Releases that under deleted distribution groups will not be filtered out.
  --scope: string # When the scope is 'tester', only includes releases that have been distributed to groups that the user belongs to.
  --top: float # The number of releases to return
  --release-id: float # The id of a release
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: published_only, var: published_only}, {name: scope, var: scope}, {name: top, var: top}, {name: releaseId, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, published_only: $published_only, scope: $scope, top: $top, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return detailed information about releases avaiable to a tester.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/filter_by_tester
# DEPRECATED
# Returns: table<build: record<branch_name: string, commit_hash: string, commit_message: string>, destination_type: string, destinations: list<record>, distribution_groups: list<record>, distribution_stores: list<record>, enabled: bool, file_extension: string, id: int, is_external_build: bool, origin: string, short_version: string, uploaded_at: string, version: string>
# operationId: releases_availableToTester
@deprecated
export def "releases-available-to-tester" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --published-only: oneof<nothing, bool> # when *true*, filters out releases that were uploaded but were never distributed. Releases that under deleted distribution groups will not be filtered out.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/filter_by_tester"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: published_only, var: published_only}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, published_only: $published_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a release.
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# operationId: releases_delete
export def "releases-delete" [
  owner_name: string
  app_name: string
  release_id: int
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
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a release with id `release_id`. If `release_id` is `latest`, return the latest release that was distributed to the current user (from all the distribution groups).
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestByUser
export def "releases-get-latest-by-user" [
  owner_name: string
  app_name: string
  release_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # when supplied, this call will also check if the given UDID is provisioned. Will be ignored for non-iOS platforms. The value will be returned in the property is_udid_provisioned.
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    query: [{name: udid, var: udid}, {name: is_install_page, var: is_install_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, udid: $udid, is_install_page: $is_install_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a release.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# Returns: record<release_notes: string>
# operationId: releases_update
export def "releases-update" [
  owner_name: string
  app_name: string
  release_id: int
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details of a release.
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}
# Returns: record<destinations: table<id: string, name: string>, enabled: bool, mandatory_update: bool, provisioning_status_url: string, release_notes: string>
# operationId: releases_updateDetails
export def "releases-update-details" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: record # Contains metadata about the build that produced the release being uploaded — shape: {branch_name?: string, commit_hash?: string, commit_message?: string}
  --enabled: oneof<nothing, bool> # Toggle this release to be enable distribute/download or not.
  --release-notes: string # Release notes for this release.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: build, var: build}, {name: enabled, var: enabled}, {name: release_notes, var: release_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, build: $build, enabled: $enabled, release_notes: $release_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Distributes a release to a group
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups
# Returns: record<id: string, mandatory_update: bool, provisioning_status_url: string>
# operationId: releases_addDistributionGroup
export def "releases-add-distribution-group" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique id of the release destination (format: uuid)
  --mandatory-update: oneof<nothing, bool> # Flag to mark the release for the provided destinations as mandatory
  --notify-testers: oneof<nothing, bool> # Flag to enable or disable notifications to testers (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: mandatory_update, var: mandatory_update}, {name: notify_testers, var: notify_testers}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, id: $id, mandatory_update: $mandatory_update, notify_testers: $notify_testers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the given distribution group from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}
# operationId: releases_deleteDistributionGroup
export def "releases-delete-distribution-group" [
  owner_name: string
  app_name: string
  release_id: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details about the specified distribution group associated with the release
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}
# operationId: releases_putDistributionGroup
export def "releases-put-distribution-group" [
  owner_name: string
  app_name: string
  release_id: int
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
  --mandatory-update: oneof<nothing, bool> # Whether a release is mandatory for the given destination
]: any -> any {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/groups/{group_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: group_id, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mandatory_update, var: mandatory_update, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, group_id: $group_id, mandatory_update: $mandatory_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return information about the provisioning profile. Only available for iOS.
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/provisioning_profile
# Returns: record<appex_profiles: list<any>, provisioning_bundle_id: string, provisioning_profile_name: string, provisioning_profile_type: string, team_identifier: string, udids: list<string>>
# operationId: provisioning_profile
export def "provisioning-profile" [
  owner_name: string
  app_name: string
  release_id: int
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
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/provisioning_profile"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Distributes a release to a store
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores
# Returns: record<id: string>
# operationId: releases_addStore
export def "releases-add-store" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique id of the release destination (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the given distribution store from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores/{store_id}
# operationId: releases_deleteDistributionStore
export def "releases-delete-distribution-store" [
  owner_name: string
  app_name: string
  release_id: int
  store_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/stores/{store_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: store_id, var: store_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, store_id: $store_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Distributes a release to a user
#
# POST /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers
# Returns: record<id: string, mandatory_update: bool, provisioning_status_url: string>
# operationId: releases_addTesters
export def "releases-add-testers" [
  owner_name: string
  app_name: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Tester's email address
  --mandatory-update: oneof<nothing, bool> # Flag to mark the release for the provided destinations as mandatory
  --notify-testers: oneof<nothing, bool> # Flag to enable or disable notifications to testers (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: mandatory_update, var: mandatory_update}, {name: notify_testers, var: notify_testers}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, email: $email, mandatory_update: $mandatory_update, notify_testers: $notify_testers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the given tester from the release
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}
# operationId: releases_deleteDistributionTester
export def "releases-delete-distribution-tester" [
  owner_name: string
  app_name: string
  release_id: int
  tester_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: tester_id, var: tester_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, tester_id: $tester_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details about the specified tester associated with the release
#
# PUT /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}
# operationId: releases_putDistributionTester
export def "releases-put-distribution-tester" [
  owner_name: string
  app_name: string
  release_id: int
  tester_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandatory-update: oneof<nothing, bool> # Whether a release is mandatory for the given destination
]: any -> any {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/testers/{tester_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: tester_id, var: tester_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mandatory_update, var: mandatory_update, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, tester_id: $tester_id, mandatory_update: $mandatory_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the resign status to the caller
#
# GET /v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/update_devices/{resign_id}
# Returns: record<error_code: string, error_message: string, status: string>
# operationId: devices_getReleaseUpdateDevicesStatus
export def "devices-get-release-update-devices-status" [
  owner_name: string
  app_name: string
  release_id: string
  resign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-provisioning-profile: oneof<nothing, bool> # A boolean value that indicates if the provisioning profile should be return in addition to the status. When set to true, the provisioning profile will be returned only when status is 'complete' or 'preparing_for_testers'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/releases/{release_id}/update_devices/{resign_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: release_id, var: release_id}, {name: resign_id, var: resign_id}]
    query: [{name: include_provisioning_profile, var: include_provisioning_profile}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, release_id: $release_id, resign_id: $resign_id, include_provisioning_profile: $include_provisioning_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the configuration for the repository
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/repo_config
# Returns: record<message: string>
# operationId: repositoryConfigurations_delete
export def "repository-configurations-delete" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/repo_config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the repository build configuration status of the app
#
# GET /v0.1/apps/{owner_name}/{app_name}/repo_config
# Returns: table<id: string, state: string, type: string, user_email: string, installation_id: string, external_user_id: string, repo_id: string, repo_url: string, service_connection_id: string>
# operationId: repositoryConfigurations_list
export def "repository-configurations-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-inactive: oneof<nothing, bool> # Include inactive configurations if none are active
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/repo_config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: includeInactive, var: include_inactive}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, include_inactive: $include_inactive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures the repository for build
#
# POST /v0.1/apps/{owner_name}/{app_name}/repo_config
# Returns: record<message: string>
# operationId: repositoryConfigurations_createOrUpdate
export def "repository-configurations-create-or-update" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --installation-id: string # The GitHub App Installation id. Required for repositories connected from GitHub App
  --external-user-id: string # The external user id from the repository provider. Required for GitLab.com repositories
  --repo-id: string # The repository id from the repository provider. Required for repositories connected from GitHub App and GitLab.com
  repo_url: string # The repository's git url, must be a HTTPS URL (e.g. https://github.com/foo/bar.git)
  --service-connection-id: string # The id of the service connection (private). Required for GitLab self-hosted repositories
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/repo_config"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: installation_id, var: installation_id}, {name: external_user_id, var: external_user_id}, {name: repo_id, var: repo_id}, {name: repo_url, var: repo_url}, {name: service_connection_id, var: service_connection_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, installation_id: $installation_id, external_user_id: $external_user_id, repo_id: $repo_id, repo_url: $repo_url, service_connection_id: $service_connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the repositories available from the source code host
#
# GET /v0.1/apps/{owner_name}/{app_name}/source_hosts/{source_host}/repositories
# Returns: table<clone_url: string, name: string>
# operationId: repositories_list
export def "repositories-list" [
  owner_name: string
  app_name: string
  source_host: string@source-host-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vsts-account-name: string # Filter repositories only for specified account and project, "vstsProjectId" is required
  --vsts-project-id: string # Filter repositories only for specified account and project, "vstsAccountName" is required
  --service-connection-id: string # The id of the service connection (private). Required for GitLab self-hosted repositories
  --form: string@form-completer # The selected form of the object
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/source_hosts/{source_host}/repositories"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: source_host, var: source_host}]
    query: [{name: vstsAccountName, var: vsts_account_name}, {name: vstsProjectId, var: vsts_project_id}, {name: service_connection_id, var: service_connection_id}, {name: form, var: form}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, source_host: $source_host, vsts_account_name: $vsts_account_name, vsts_project_id: $vsts_project_id, service_connection_id: $service_connection_id, form: $form
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Application specific store service status
#
# GET /v0.1/apps/{owner_name}/{app_name}/store_service_status
# Returns: record<service: string, status: string, valid_until: int>
# operationId: storeNotifications_getNotificationByAppId
export def "store-notifications-get-notification-by-app-id" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/store_service_status"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about the currently active subscriptions, if any
#
# GET /v0.1/apps/{owner_name}/{app_name}/subscriptions
# Returns: record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>>
# operationId: test_getSubscriptions
export def "test-get-subscriptions" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/subscriptions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept a free trial subscription
#
# POST /v0.1/apps/{owner_name}/{app_name}/subscriptions
# Returns: record<active: bool, concurrentDevicesLimit: int, daysLeft: float, endsAt: string, id: string, runningDevices: int, startsAt: string, tier: record<name: string>>
# operationId: test_createSubscription
export def "test-create-subscription" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/subscriptions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all uploads for the specified application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads
# Returns: table<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: list<record>, timestamp: string, user: record<display_name: string, email: string>>
# operationId: symbolUploads_list
export def "symbol-uploads-list" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The maximum number of results to return. (format: int64, default: 30)
  --status: string@status-completer-2 # Filter results by the current status of a symbol upload: * all: all states in the symbol upload process. Includes created, aborted, committed, processing, indexed and failed states * uploaded: all states after package is uploaded. Includes committed, processing, indexed and failed states * processed: symbol upload processing is completed. Includes indexed and failed states.
  --symbol-type: string@symbol-type-completer # The type of symbols
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: top, var: top}, {name: status, var: status}, {name: symbol_type, var: symbol_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, top: $top, status: $status, symbol_type: $symbol_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begins the symbol upload process for a new set of symbols for the specified application
#
# POST /v0.1/apps/{owner_name}/{app_name}/symbol_uploads
# Returns: record<expiration_date: string, symbol_upload_id: string, upload_url: string>
# operationId: symbolUploads_create
export def "symbol-uploads-create" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build: string # The build number. Optional for Apple. Required for Android.
  --client-callback: string # The callback URL that the client can optionally provide to get status updates for the current symbol upload
  --file-name: string # The file name for the symbol upload
  symbol_type: string@symbol-type-completer # The type of the symbol for the current symbol upload
  --version: string # The version number. Optional for Apple. Required for Android.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: build, var: build}, {name: client_callback, var: client_callback}, {name: file_name, var: file_name}, {name: symbol_type, var: symbol_type}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build: $build, client_callback: $client_callback, file_name: $file_name, symbol_type: $symbol_type, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a symbol upload by id for the specified application
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# Returns: record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>
# operationId: symbolUploads_delete
export def "symbol-uploads-delete" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_upload_id, var: symbol_upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_upload_id: $symbol_upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a symbol upload by id for the specified application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# Returns: record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>
# operationId: symbolUploads_get
export def "symbol-uploads-get" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_upload_id, var: symbol_upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_upload_id: $symbol_upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commits or aborts the symbol upload process for a new set of symbols for the specified application
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}
# Returns: record<app_id: string, file_name: string, file_size: float, origin: string, status: string, symbol_type: string, symbol_upload_id: string, symbols_uploaded: table<platform: string, symbol_id: string>, timestamp: string, user: record<display_name: string, email: string>>
# operationId: symbolUploads_complete
export def "symbol-uploads-complete" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-3 # The desired operation for the symbol upload
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_upload_id, var: symbol_upload_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_upload_id: $symbol_upload_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the URL to download the symbol upload
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}/location
# Returns: record<uri: string>
# operationId: symbolUploads_getLocation
export def "symbol-uploads-get-location" [
  owner_name: string
  app_name: string
  symbol_upload_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbol_uploads/{symbol_upload_id}/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_upload_id, var: symbol_upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_upload_id: $symbol_upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of all symbols for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols
# Returns: table<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>
# operationId: symbols_list
export def "symbols-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbols"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a particular symbol by id (uuid) for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}
# Returns: record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>
# operationId: symbols_get
export def "symbols-get" [
  owner_name: string
  app_name: string
  symbol_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_id, var: symbol_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_id: $symbol_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks a symbol by id (uuid) as ignored
#
# POST /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/ignore
# Returns: record<alternate_symbol_ids: list<string>, app_id: string, build: string, origin: string, platform: string, status: string, symbol_id: string, symbol_upload_id: string, type: string, url: string, version: string>
# operationId: symbols_ignore
export def "symbols-ignore" [
  owner_name: string
  app_name: string
  symbol_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/ignore"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_id, var: symbol_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_id: $symbol_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the URL to download the symbol
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/location
# Returns: record<uri: string>
# operationId: symbols_getLocation
export def "symbols-get-location" [
  owner_name: string
  app_name: string
  symbol_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/location"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_id, var: symbol_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_id: $symbol_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a particular symbol by id (uuid) for the provided application
#
# GET /v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/status
# Returns: record<app_id: string, status: string, symbol_id: string>
# operationId: symbols_getStatus
export def "symbols-get-status" [
  owner_name: string
  app_name: string
  symbol_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/symbols/{symbol_id}/status"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: symbol_id, var: symbol_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, symbol_id: $symbol_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of all teams that have access to the app.
#
# GET /v0.1/apps/{owner_name}/{app_name}/teams
# Returns: table<description: string, display_name: string, id: string, name: string, permissions: list<string>>
# operationId: apps_getTeams
export def "apps-get-teams" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/teams"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the endpoints available for Test apps data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export
# Returns: record<resources: table<path: string, rel: string>>
# operationId: test_gdprExportApps
export def "test-gdpr-export-apps" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists app data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/apps
# Returns: record<hash_files_url: string>
# operationId: test_gdprExportApp
export def "test-gdpr-export-app" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export/apps"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists file set file data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/fileSetFiles
# Returns: record<app_upload_id: string, hash_file_id: string, hash_file_url: string, path: string>
# operationId: test_gdprExportFileSetFile
export def "test-gdpr-export-file-set-file" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export/fileSetFiles"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists hash file data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/hashFiles
# Returns: record<filename: string, id: string>
# operationId: test_gdprExportHashFile
export def "test-gdpr-export-hash-file" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export/hashFiles"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists pipeline test data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/pipelineTests
# Returns: record<app_upload_id: string, test_parameters: record>
# operationId: test_gdprExportPipelineTest
export def "test-gdpr-export-pipeline-test" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export/pipelineTests"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists test run data
#
# GET /v0.1/apps/{owner_name}/{app_name}/test/export/testRuns
# Returns: record<app_hash_file_id: string, app_hash_file_url: string, app_icon_url: string, dsym_hash_file_id: string, dsym_hash_file_url: string, id: string, locale: string>
# operationId: test_gdprExportTestRun
export def "test-gdpr-export-test-run" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test/export/testRuns"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of test runs
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs
# Returns: table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>
# operationId: test_getTestRuns
export def "test-get-test-runs" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs
# operationId: test_createTestRun
export def "test-create-test-run" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logically deletes a test run
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}
# Returns: record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>
# operationId: test_archiveTestRun
export def "test-archive-test-run" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single test runs
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}
# Returns: record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>
# operationId: test_getTestRun
export def "test-get-test-run" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads file for a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/files
# operationId: test_startUploadingFile
export def "test-start-uploading-file" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/files"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds file with the given hash to a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes
# operationId: test_uploadHash
export def "test-upload-hash" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --byte-range: string # Range of bytes required to verify ownership of the file
  checksum: string # SHA256 hash of the file
  file_type: string@file-type-completer # Type of the file
  relative_path: string # Relative path of the file
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: byte_range, var: byte_range}, {name: checksum, var: checksum}, {name: file_type, var: file_type}, {name: relative_path, var: relative_path}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id, byte_range: $byte_range, checksum: $checksum, file_type: $file_type, relative_path: $relative_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds file with the given hash to a test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes/batch
# Returns: table<checksum: string, fileType: string, relativePath: string, uploadStatus: record<location: string, statusCode: float>>
# operationId: test_uploadHashesBatch
export def "test-upload-hashes-batch" [
  owner_name: string
  app_name: string
  test_run_id: string
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/hashes/batch"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single test report
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/report
# Returns: record<app_upload_id: string, date: string, date_finished: string, device_logs: table<appium_log: string, device_log: string, device_snapshot_id: string, test_log: string>, errorMessage: string, features: table<failed: float, name: string, peakDuration: float, peakMemory: float, skipped: float, tests: list>, finished_device_snapshots: list<string>, id: string, platform: string, revision: float, schema_version: float, snapshot_fatal_errors: table<device_snapshot_id: string, error_message: string, error_title: string>, stats: record<artifacts: record, devices: float, devices_failed: float, devices_finished: float, devices_not_runned: float, devices_skipped: float, failed: float, filesize: float, os: float, passed: float, skipped: float, step_count: float, total: float, totalDeviceMinutes: float>, testType: string>
# operationId: test_getTestReport
export def "test-get-test-report" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/report"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts test run
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/start
# Returns: record<accepted_devices: list<string>, rejected_devices: list<string>>
# operationId: test_startTestRun
export def "test-start-test-run" [
  owner_name: string
  app_name: string
  test_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_selection: string # Device selection string.
  --language: string # Language that should be used to run tests.
  --locale: string # Locale that should be used to run tests.
  test_framework: string # Test framework used by tests.
  --test-parameters: record # A JSON dictionary with additional test parameters
  --test-series: string # Name of the test series.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/start"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: device_selection, var: device_selection}, {name: language, var: language}, {name: locale, var: locale}, {name: test_framework, var: test_framework}, {name: test_parameters, var: test_parameters}, {name: test_series, var: test_series}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id, device_selection: $device_selection, language: $language, locale: $locale, test_framework: $test_framework, test_parameters: $test_parameters, test_series: $test_series
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets state of the test run
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/state
# Returns: record<exit_code: int, message: list<string>, wait_time: int>
# operationId: test_getTestRunState
export def "test-get-test-run-state" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/state"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a test run execution
#
# PUT /v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/stop
# Returns: record<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>
# operationId: test_stopTestRun
export def "test-stop-test-run" [
  owner_name: string
  app_name: string
  test_run_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_runs/{test_run_id}/stop"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_run_id, var: test_run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_run_id: $test_run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all test series for an application
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_series
# Returns: table<mostRecentActivity: string, name: string, slug: string, testRuns: list<record>>
# operationId: test_getAllTestSeries
export def "test-get-all-test-series" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query string to filter test series
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/test_series"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new test series for an application
#
# POST /v0.1/apps/{owner_name}/{app_name}/test_series
# Returns: record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>>
# operationId: test_createTestSeries
export def "test-create-test-series" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the new test series
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/test_series"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single test series
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}
# operationId: test_deleteTestSeries
export def "test-delete-test-series" [
  owner_name: string
  app_name: string
  test_series_slug: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_series_slug, var: test_series_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_series_slug: $test_series_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates name and slug of a test series
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}
# Returns: record<mostRecentActivity: string, name: string, slug: string, testRuns: table<completed: bool, date: string, failed: float, passed: float, statusDescription: string>>
# operationId: test_patchTestSeries
export def "test-patch-test-series" [
  owner_name: string
  app_name: string
  test_series_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the new test series
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_series_slug, var: test_series_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_series_slug: $test_series_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all test runs for a given test series
#
# GET /v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}/test_runs
# Returns: table<appVersion: string, date: string, description: string, id: string, platform: string, resultStatus: string, runStatus: string, state: string, stats: record<devices: float, devicesFailed: float, devicesFinished: float, failed: float, passed: float, peakMemory: float, skipped: float, total: float, totalDeviceMinutes: float>, status: string, testSeries: string, testType: string>
# operationId: test_getAllTestRunsForSeries
export def "test-get-all-test-runs-for-series" [
  owner_name: string
  app_name: string
  test_series_slug: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/test_series/{test_series_slug}/test_runs"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: test_series_slug, var: test_series_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, test_series_slug: $test_series_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the testers associated with the app specified with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}/testers
# Returns: table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>
# operationId: apps_listTesters
export def "apps-list-testers" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/testers"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the given tester from the all releases
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/testers/{tester_id}
# operationId: releases_deleteTesterFromDestinations
export def "releases-delete-tester-from-destinations" [
  owner_name: string
  app_name: string
  tester_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/testers/{tester_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: tester_id, var: tester_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, tester_id: $tester_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns available toolsets for application
#
# GET /v0.1/apps/{owner_name}/{app_name}/toolsets
# Returns: record<node: table<current: bool, name: string>, xamarin: table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list>, xcode: table<current: bool, name: string>>
# operationId: builds_listToolsets
export def "builds-list-toolsets" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tools: string@tools-completer # Toolset name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/apps/{owner_name}/{app_name}/toolsets"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    query: [{name: tools, var: tools}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, tools: $tools
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers ownership of an app to a different user or organization
#
# POST /v0.1/apps/{owner_name}/{app_name}/transfer/{destination_owner_name}
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_transferOwnership
export def "apps-transfer-ownership" [
  owner_name: string
  app_name: string
  destination_owner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/transfer/{destination_owner_name}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: destination_owner_name, var: destination_owner_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, destination_owner_name: $destination_owner_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers ownership of an app to a new organization
#
# POST /v0.1/apps/{owner_name}/{app_name}/transfer_to_org
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: apps_transferToOrg
export def "apps-transfer-to-org" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/transfer_to_org"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate a new release upload. This API is part of multi-step upload process.
#
# POST /v0.1/apps/{owner_name}/{app_name}/uploads/releases
# Returns: record<id: string, package_asset_id: string, token: string, upload_domain: string, url_encoded_token: string>
# operationId: releases_createReleaseUpload
export def "releases-create-release-upload" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-number: string # User defined build number
  --build-version: string # User defined build version
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/uploads/releases"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: build_number, var: build_number}, {name: build_version, var: build_version}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, build_number: $build_number, build_version: $build_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current status of the release upload.
#
# GET /v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}
# Returns: record<error_details: string, id: string, release_distinct_id: float, release_url: any, upload_status: string>
# operationId: releases_getReleaseUploadStatus
export def "releases-get-release-upload-status" [
  owner_name: string
  app_name: string
  upload_id: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: upload_id, var: upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, upload_id: $upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the current status of the release upload.
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}
# Returns: record<id: string, upload_status: string>
# operationId: releases_updateReleaseUploadStatus
export def "releases-update-release-upload-status" [
  owner_name: string
  app_name: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extract: oneof<nothing, bool> # A flag that indicates to extract release or not, true by default
  upload_status: string@upload-status-completer # The new status of the release upload
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/uploads/releases/{upload_id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: upload_id, var: upload_id}]
    query: [{name: extract, var: extract}]
    body: {content_type: "application/json", kind: json, fields: [{name: upload_status, var: upload_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, upload_id: $upload_id, extract: $extract, upload_status: $upload_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists device sets belonging to the user
#
# GET /v0.1/apps/{owner_name}/{app_name}/user/device_sets
# Returns: table<deviceConfigurations: list<record>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_listDeviceSetsOfUser
export def "test-list-device-sets-of-user" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/user/device_sets"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a device set belonging to the user
#
# POST /v0.1/apps/{owner_name}/{app_name}/user/device_sets
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_createDeviceSetOfUser
export def "test-create-device-set-of-user" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/apps/{owner_name}/{app_name}/user/device_sets"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, devices: $devices, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a device set belonging to the user
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# operationId: test_deleteDeviceSetOfUser
export def "test-delete-device-set-of-user" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a device set belonging to the user
#
# GET /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_getDeviceSetOfUser
export def "test-get-device-set-of-user" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a device set belonging to the user
#
# PUT /v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}
# Returns: record<deviceConfigurations: table<id: string, image: record, model: record, os: string, osName: string>, id: string, manufacturerCount: float, name: string, osVersionCount: float, owner: record<displayName: string, id: string, name: string, type: string>, slug: string>
# operationId: test_updateDeviceSetOfUser
export def "test-update-device-set-of-user" [
  owner_name: string
  app_name: string
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
  devices: list<string> # List of device IDs
  name: string # The name of the device set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v0.1/apps/{owner_name}/{app_name}/user/device_sets/{id}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: devices, var: devices}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, id: $id, devices: $devices, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the users associated with the app specified with the given app name which belongs to the given owner.
#
# GET /v0.1/apps/{owner_name}/{app_name}/users
# Returns: table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>
# operationId: users_list
export def "users-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/users"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the user from the app
#
# DELETE /v0.1/apps/{owner_name}/{app_name}/users/{user_email}
# operationId: apps_removeUser
export def "apps-remove-user" [
  owner_name: string
  app_name: string
  user_email: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/users/{user_email}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: user_email, var: user_email}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user permission for the app
#
# PATCH /v0.1/apps/{owner_name}/{app_name}/users/{user_email}
# operationId: apps_updateUserPermissions
export def "apps-update-user-permissions" [
  owner_name: string
  app_name: string
  user_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions the user has for the app
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v0.1/apps/{owner_name}/{app_name}/users/{user_email}"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}, {name: user_email, var: user_email}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, user_email: $user_email, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of application versions.
#
# GET /v0.1/apps/{owner_name}/{app_name}/versions
# DEPRECATED
# Returns: table<app_id: string, app_version: string, app_version_id: string, build_number: string, display_name: string>
# operationId: crashes_getAppVersions
@deprecated
export def "crashes-get-app-versions" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/versions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get web hooks configured for a particular app
#
# GET /v0.1/apps/{owner_name}/{app_name}/webhooks
# Returns: record<values: table<enabled: bool, event_types: list, id: string, name: string, url: string>>
# operationId: webhooks_list
export def "webhooks-list" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/webhooks"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Xamarin SDK bundles available to this app
#
# GET /v0.1/apps/{owner_name}/{app_name}/xamarin_sdk_bundles
# DEPRECATED
# Returns: table<current: bool, monoVersion: string, sdkBundle: string, stable: bool, xcodeVersions: list<string>>
# operationId: builds_listXamarinSDKBundles
@deprecated
export def "builds-list-xamarin-sdk-bundles" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/xamarin_sdk_bundles"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Xcode versions available to this app
#
# GET /v0.1/apps/{owner_name}/{app_name}/xcode_versions
# DEPRECATED
# Returns: table<current: bool, name: string>
# operationId: builds_listXcodeVersions
@deprecated
export def "builds-list-xcode-versions" [
  owner_name: string
  app_name: string
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
    path: "/v0.1/apps/{owner_name}/{app_name}/xcode_versions"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of azure subscriptions for the user
#
# GET /v0.1/azure_subscriptions
# Returns: table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>
# operationId: azureSubscription_listForUser
export def "azure-subscription-list-for-user" [
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
    path: "/v0.1/azure_subscriptions"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated Billing Information for the requesting user and the organizations in which the user is an admin.
#
# GET /v0.1/billing/allAccountsAggregated
# Returns: record<aggregatedBillings: record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record, testService: record>, id: string, timestamp: string, usage: record<buildService: record, testService: record>, version: string>>
# operationId: billingAggregatedInformation_getAll
export def "billing-aggregated-information-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/billing/allAccountsAggregated"
    query: [{name: service, var: service}, {name: period, var: period}, {name: showOriginalPlans, var: show_original_plans}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    service: $service, period: $period, show_original_plans: $show_original_plans
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all invitations sent by the caller
#
# GET /v0.1/invitations/sent
# Returns: table<app: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record, release_type: string, app_secret: string, azure_subscription: record, created_at: string, member_permissions: list, origin: string, platform: string, updated_at: string>, invitation_id: string, organization: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>>
# operationId: invitations_sent
export def "invitations-sent" [
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
    path: "/v0.1/invitations/sent"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report deploy of specified release
#
# POST /v0.1/legacy/reportStatus/deploy
# operationId: legacyCodePushAcquisition_updateInstallsStatus
export def "legacy-code-push-acquisition-update-installs-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  --deployment-key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/legacy/reportStatus/deploy"
    body: {content_type: "application/json", kind: json, fields: [{name: appVersion, var: app_version}, {name: clientUniqueId, var: client_unique_id}, {name: deploymentKey, var: deployment_key}, {name: label, var: label}, {name: previousDeploymentKey, var: previous_deployment_key}, {name: previousLabelOrAppVersion, var: previous_label_or_app_version}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_version: $app_version, client_unique_id: $client_unique_id, deployment_key: $deployment_key, label: $label, previous_deployment_key: $previous_deployment_key, previous_label_or_app_version: $previous_label_or_app_version, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report download of specified release
#
# POST /v0.1/legacy/reportStatus/download
# operationId: legacyCodePushAcquisition_updateDownloadStatus
export def "legacy-code-push-acquisition-update-download-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  --deployment-key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/legacy/reportStatus/download"
    body: {content_type: "application/json", kind: json, fields: [{name: appVersion, var: app_version}, {name: clientUniqueId, var: client_unique_id}, {name: deploymentKey, var: deployment_key}, {name: label, var: label}, {name: previousDeploymentKey, var: previous_deployment_key}, {name: previousLabelOrAppVersion, var: previous_label_or_app_version}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_version: $app_version, client_unique_id: $client_unique_id, deployment_key: $deployment_key, label: $label, previous_deployment_key: $previous_deployment_key, previous_label_or_app_version: $previous_label_or_app_version, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check for updates
#
# GET /v0.1/legacy/updateCheck
# Returns: record<updateInfo: record<appVersion: string, description: string, isDisabled: bool, isMandatory: bool, rollout: int, downloadURL: string, isAvailable: bool, label: string, packageHash: string, packageSize: float, shouldRunBinaryVersion: bool, updateAppVersion: bool>>
# operationId: legacyCodePushAcquisition_updateCheck
export def "legacy-code-push-acquisition-update-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-key: string
  --app-version: string
  --package-hash: string
  --label: string
  --client-unique-id: string
  --is-companion: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/legacy/updateCheck"
    query: [{name: deploymentKey, var: deployment_key}, {name: appVersion, var: app_version}, {name: packageHash, var: package_hash}, {name: label, var: label}, {name: clientUniqueId, var: client_unique_id}, {name: isCompanion, var: is_companion}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    deployment_key: $deployment_key, app_version: $app_version, package_hash: $package_hash, label: $label, client_unique_id: $client_unique_id, is_companion: $is_companion
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of organizations the requesting user has access to
#
# GET /v0.1/orgs
# Returns: table<display_name: string, name: string, origin: string>
# operationId: organizations_list
export def "organizations-list" [
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
    path: "/v0.1/orgs"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new organization and returns it to the caller
#
# POST /v0.1/orgs
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: organizations_createOrUpdate
export def "organizations-create-or-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the organization
  --name: string # The name of the organization used in URLs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs"
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated Billing Information for a given Organization.
#
# GET /v0.1/orgs/{orgName}/billing/aggregated
# Returns: record<azureSubscriptionId: string, azureSubscriptionState: string, billingPlans: record<buildService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>, testService: record<canSelectTrialPlan: bool, currentBillingPeriod: record, lastTrialPlanExpirationTime: string>>, id: string, timestamp: string, usage: record<buildService: record<currentUsagePeriod: record>, testService: record<currentUsagePeriod: record>>, version: string>
# operationId: billingAggregatedInformation_getForOrg
export def "billing-aggregated-information-get-for-org" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string@service-completer # Type of service that should be included in the Billing Information
  --period: string@period-completer # Type of period that should be included in the Billing Information
  --show-original-plans: oneof<nothing, bool> # Controls whether the API should show the original plan when Azure Subscription is not enabled
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/orgs/{orgName}/billing/aggregated"
    path_params: [{name: orgName, var: org_name}]
    query: [{name: service, var: service}, {name: period, var: period}, {name: showOriginalPlans, var: show_original_plans}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, service: $service, period: $period, show_original_plans: $show_original_plans
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single organization
#
# DELETE /v0.1/orgs/{org_name}
# operationId: organizations_delete
export def "organizations-delete" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of a single organization
#
# GET /v0.1/orgs/{org_name}
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: organizations_get
export def "organizations-get" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of organizations the requesting user has access to
#
# PATCH /v0.1/orgs/{org_name}
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: organizations_update
export def "organizations-update" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The full (friendly) name of the organization.
  --name: string # The name of the organization used in URLs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of apps for the organization
#
# GET /v0.1/orgs/{org_name}/apps
# Returns: table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_listForOrg
export def "apps-list-for-org" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/apps"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new app for the organization and returns it to the caller
#
# POST /v0.1/orgs/{org_name}/apps
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_createForOrg
export def "apps-create-for-org" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A short text describing the app
  display_name: string # The descriptive name of the app. This can contain any characters
  --name: string # The name of the app used in URLs
  os: string@os-completer # The OS the app will be running on
  platform: string@platform-completer # The platform of the app
  --release-type: string # A one-word descriptive release-type value that starts with a capital letter but is otherwise lowercase
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/apps"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: name, var: name}, {name: os, var: os}, {name: platform, var: platform}, {name: release_type, var: release_type}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: x-api-token
  } {
    org_name: $org_name, description: $description, display_name: $display_name, name: $name, os: $os, platform: $platform, release_type: $release_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the uploaded organization avatar
#
# DELETE /v0.1/orgs/{org_name}/avatar
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: organization_deleteAvatar
export def "organization-delete-avatar" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/avatar"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the organization avatar
#
# POST /v0.1/orgs/{org_name}/avatar
# Returns: record<avatar_url: string, created_at: string, display_name: string, id: string, name: string, origin: string, updated_at: string>
# operationId: organization_updateAvatar
export def "organization-update-avatar" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The image for an Organization avatar to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/avatar"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: avatar, var: avatar}], files: [avatar]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, avatar: $avatar
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of azure subscriptions for the organization
#
# GET /v0.1/orgs/{org_name}/azure_subscriptions
# Returns: table<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>
# operationId: azureSubscription_listForOrg
export def "azure-subscription-list-for-org" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/azure_subscriptions"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of distribution groups in the org specified
#
# GET /v0.1/orgs/{org_name}/distribution_groups
# Returns: table<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_listForOrg
export def "distribution-groups-list-for-org" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/distribution_groups"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a disribution goup which can be shared across apps under an organization
#
# POST /v0.1/orgs/{org_name}/distribution_groups
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_createForOrg
export def "distribution-groups-create-for-org" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The display name of the distribution group. If not specified, the name will be used.
  name: string # The name of the distribution group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    org_name: $org_name, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single distribution group from an org with a given distribution group name
#
# DELETE /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# operationId: distributionGroups_deleteForOrg
export def "distribution-groups-delete-for-org" [
  org_name: string
  distribution_group_name: string
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
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a single distribution group in org for a given distribution group name
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_getForOrg
export def "distribution-groups-get-for-org" [
  org_name: string
  distribution_group_name: string
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
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one given distribution group name in an org
#
# PATCH /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}
# Returns: record<display_name: string, id: string, is_public: bool, name: string, origin: string>
# operationId: distributionGroups_patchForOrg
export def "distribution-groups-patch-for-org" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-public: oneof<nothing, bool> # Whether the distribution group is public
  --name: string # The name of the distribution group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_public, var: is_public}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, is_public: $is_public, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get apps from a distribution group in an org
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps
# Returns: table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, origin: string, platform: string>
# operationId: distributionGroups_getApps
export def "distribution-groups-get-apps" [
  org_name: string
  distribution_group_name: string
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
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add apps to distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps
# operationId: distributionGroups_addApps
export def "distribution-groups-add-apps" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps: list # The list of apps to add to distribution group — item shape: {name: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: apps, var: apps}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, apps: $apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete apps from distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps/bulk_delete
# operationId: distributionGroups_bulkDeleteApps
export def "distribution-groups-bulk-delete-apps" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps: list # The list of apps to delete from the distribution group — item shape: {name: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/apps/bulk_delete"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: apps, var: apps}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, apps: $apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of member in the distribution group specified
#
# GET /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members
# Returns: table<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, invite_pending: bool, name: string>
# operationId: distributionGroups_listUsersForOrg
export def "distribution-groups-list-users-for-org" [
  org_name: string
  distribution_group_name: string
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
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts an array of user email addresses to get added to the specified group
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members
# Returns: table<code: string, invite_pending: bool, message: string, status: int, user_email: string>
# operationId: distributionGroups_addUsersForOrg
export def "distribution-groups-add-users-for-org" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete testers from distribution group in an org
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members/bulk_delete
# operationId: distributionGroups_bulkDeleteUsers
export def "distribution-groups-bulk-delete-users" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/members/bulk_delete"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend shared distribution group invite notification to previously invited testers
#
# POST /v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/resend_invite
# operationId: distributionGroups_resendSharedInvite
export def "distribution-groups-resend-shared-invite" [
  org_name: string
  distribution_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-emails: list<string> # The list of emails of the users
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/distribution_groups/{distribution_group_name}/resend_invite"
    path_params: [{name: org_name, var: org_name}, {name: distribution_group_name, var: distribution_group_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_emails, var: user_emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, distribution_group_name: $distribution_group_name, user_emails: $user_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of distribution groups with details for an organization
#
# GET /v0.1/orgs/{org_name}/distribution_groups_details
# Returns: table<display_name: string, id: string, is_public: bool, name: string, origin: string, apps: list<record>, total_apps_count: float, total_users_count: float>
# operationId: distributionGroups_detailsForOrg
export def "distribution-groups-details-for-org" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apps-limit: float # The max number of apps to include in the response
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/orgs/{org_name}/distribution_groups_details"
    path_params: [{name: org_name, var: org_name}]
    query: [{name: apps_limit, var: apps_limit}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, apps_limit: $apps_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user's invitation to an organization
#
# DELETE /v0.1/orgs/{org_name}/invitations
# operationId: orgInvitations_delete
export def "org-invitations-delete" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_email: string # The user's email address
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v0.1/orgs/{org_name}/invitations"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_email, var: user_email}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pending invitations for the organization
#
# GET /v0.1/orgs/{org_name}/invitations
# Returns: table<email: string, id: string, role: string>
# operationId: orgInvitations_listPending
export def "org-invitations-list-pending" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/invitations"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invites a new or existing user to an organization
#
# POST /v0.1/orgs/{org_name}/invitations
# operationId: orgInvitations_create
export def "org-invitations-create" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role
  user_email: string # The user's email address
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/invitations"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}, {name: user_email, var: user_email}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, role: $role, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the role of an invited user to be changed
#
# PATCH /v0.1/orgs/{org_name}/invitations/{email}
# operationId: orgInvitations_update
export def "org-invitations-update" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role in the organizatiion
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}/invitations/{email}"
    path_params: [{name: org_name, var: org_name}, {name: email, var: email}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, email: $email, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an existing organization invitation for the user and sends a new one
#
# POST /v0.1/orgs/{org_name}/invitations/{email}/resend
# operationId: orgInvitations_sendNewInvitation
export def "org-invitations-send-new-invitation" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The role of the user to be added
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/invitations/{email}/resend"
    path_params: [{name: org_name, var: org_name}, {name: email, var: email}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, email: $email, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user's invitation to an organization
#
# POST /v0.1/orgs/{org_name}/invitations/{email}/revoke
# operationId: orgInvitations_
export def "org-invitations" [
  org_name: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/invitations/{email}/revoke"
    path_params: [{name: org_name, var: org_name}, {name: email, var: email}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, email: $email, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of all teams in this org
#
# GET /v0.1/orgs/{org_name}/teams
# Returns: table<description: string, display_name: string, id: string, name: string>
# operationId: teams_listAll
export def "teams-list-all" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/teams"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a team and returns it
#
# POST /v0.1/orgs/{org_name}/teams
# Returns: table<description: string, display_name: string, id: string, name: string>
# operationId: teams_createTeam
export def "teams-create-team" [
  org_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the team
  display_name: string # The display name of the team
  --name: string # The name of the team
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/teams"
    path_params: [{name: org_name, var: org_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    org_name: $org_name, description: $description, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single team
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}
# operationId: teams_delete
export def "teams-delete" [
  org_name: string
  team_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the details of a single team
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}
# Returns: record<description: string, display_name: string, id: string, name: string>
# operationId: teams_getTeam
export def "teams-get-team" [
  org_name: string
  team_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a single team
#
# PATCH /v0.1/orgs/{org_name}/teams/{team_name}
# Returns: record<description: string, display_name: string, id: string, name: string>
# operationId: teams_update
export def "teams-update" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string # The new display name of the team
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}/teams/{team_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, display_name: $display_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the apps a team has access to
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}/apps
# Returns: table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>
# operationId: teams_listApps
export def "teams-list-apps" [
  org_name: string
  team_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/apps"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an app to a team
#
# POST /v0.1/orgs/{org_name}/teams/{team_name}/apps
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>
# operationId: teams_addApp
export def "teams-add-app" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the app to be added to the distribution group
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/apps"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an app from a team
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}
# operationId: teams_removeApp
export def "teams-remove-app" [
  org_name: string
  team_name: string
  app_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}, {name: app_name, var: app_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, app_name: $app_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the permissions the team has to the app
#
# PATCH /v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}
# Returns: record<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string, team_permissions: list<string>>
# operationId: teams_updatePermissions
export def "teams-update-permissions" [
  org_name: string
  team_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  permissions: list<string> # The permissions all members of the team have on the app
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/apps/{app_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, app_name: $app_name, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the users of a team which is owned by an organization
#
# GET /v0.1/orgs/{org_name}/teams/{team_name}/users
# Returns: record<display_name: string, email: string, name: string, role: any>
# operationId: teams_getUsers
export def "teams-get-users" [
  org_name: string
  team_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/users"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new user to a team that is owned by an organization
#
# POST /v0.1/orgs/{org_name}/teams/{team_name}/users
# Returns: record<display_name: string, email: string, name: string, role: any>
# operationId: teams_addUser
export def "teams-add-user" [
  org_name: string
  team_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_email: string # The user's email address
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/users"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_email, var: user_email}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, user_email: $user_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a team that is owned by an organization
#
# DELETE /v0.1/orgs/{org_name}/teams/{team_name}/users/{user_name}
# operationId: teams_removeUser
export def "teams-remove-user" [
  org_name: string
  team_name: string
  user_name: string
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
    path: "/v0.1/orgs/{org_name}/teams/{team_name}/users/{user_name}"
    path_params: [{name: org_name, var: org_name}, {name: team_name, var: team_name}, {name: user_name, var: user_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, team_name: $team_name, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a unique list of users including the whole organization members plus testers in any shared group of that org
#
# GET /v0.1/orgs/{org_name}/testers
# Returns: table<display_name: string, email: string, name: string>
# operationId: distributionGroups_listAllTestersForOrg
export def "distribution-groups-list-all-testers-for-org" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/testers"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of users that belong to an organization
#
# GET /v0.1/orgs/{org_name}/users
# Returns: table<display_name: string, email: string, joined_at: string, name: string, role: string>
# operationId: users_listForOrg
export def "users-list-for-org" [
  org_name: string
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
    path: "/v0.1/orgs/{org_name}/users"
    path_params: [{name: org_name, var: org_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from an organization.
#
# DELETE /v0.1/orgs/{org_name}/users/{user_name}
# operationId: users_removeFromOrg
export def "users-remove-from-org" [
  org_name: string
  user_name: string
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
    path: "/v0.1/orgs/{org_name}/users/{user_name}"
    path_params: [{name: org_name, var: org_name}, {name: user_name, var: user_name}]
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    org_name: $org_name, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user information from an organization by name - if there is explicit permission return it, if not if not return highest implicit permission
#
# GET /v0.1/orgs/{org_name}/users/{user_name}
# Returns: record<display_name: string, email: string, joined_at: string, name: string, role: string>
# operationId: users_getForOrg
export def "users-get-for-org" [
  org_name: string
  user_name: string
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
    path: "/v0.1/orgs/{org_name}/users/{user_name}"
    path_params: [{name: org_name, var: org_name}, {name: user_name, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given organization user
#
# PATCH /v0.1/orgs/{org_name}/users/{user_name}
# Returns: record<display_name: string, email: string, joined_at: string, name: string, role: string>
# operationId: users_updateOrgRole
export def "users-update-org-role" [
  org_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # The user's role in the organizatiion
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/orgs/{org_name}/users/{user_name}"
    path_params: [{name: org_name, var: org_name}, {name: user_name, var: user_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, user_name: $user_name, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user apps information from an organization by name
#
# GET /v0.1/orgs/{org_name}/users/{user_name}/apps
# Returns: table<description: string, display_name: string, icon_source: string, icon_url: string, id: string, name: string, os: string, owner: record<avatar_url: string, display_name: string, email: string, id: string, name: string, type: string>, release_type: string, app_secret: string, azure_subscription: record<is_billable: bool, is_billing: bool, is_microsoft_internal: bool, subscription_id: string, subscription_name: string, tenant_id: string>, created_at: string, member_permissions: list<string>, origin: string, platform: string, updated_at: string>
# operationId: apps_getForOrgUser
export def "apps-get-for-org-user" [
  org_name: string
  user_name: string
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
    path: "/v0.1/orgs/{org_name}/users/{user_name}/apps"
    path_params: [{name: org_name, var: org_name}, {name: user_name, var: user_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    org_name: $org_name, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the manifest.plist in XML format for installing the release on a device. Only available for iOS.
#
# GET /v0.1/public/apps/{app_id}/releases/{release_id}/ios_manifest
# operationId: releases_getIosManifest
export def "releases-get-ios-manifest" [
  app_id: string
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # A hash that authorizes the download if it matches the release info. (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/v0.1/public/apps/{app_id}/releases/{release_id}/ios_manifest"
    path_params: [{name: app_id, var: app_id}, {name: release_id, var: release_id}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_id: $app_id, release_id: $release_id, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notify download(s) for the provided distribution release(s).
#
# POST /v0.1/public/apps/{owner_name}/{app_name}/install_analytics
# operationId: distibutionReleases_installAnalytics
export def "distibution-releases-install-analytics" [
  owner_name: string
  app_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --releases: list # item shape: {distribution_group_id: string, release_id: int, user_id: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/public/apps/{owner_name}/{app_name}/install_analytics"
    path_params: [{name: owner_name, var: owner_name}, {name: app_name, var: app_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: releases, var: releases}]}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    owner_name: $owner_name, app_name: $app_name, releases: $releases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report Deployment status metric
#
# POST /v0.1/public/codepush/report_status/deploy
# operationId: codePushAcquisition_updateDeployStatus
export def "code-push-acquisition-update-deploy-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  deployment_key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/public/codepush/report_status/deploy"
    body: {content_type: "application/json", kind: json, fields: [{name: app_version, var: app_version}, {name: client_unique_id, var: client_unique_id}, {name: deployment_key, var: deployment_key}, {name: label, var: label}, {name: previous_deployment_key, var: previous_deployment_key}, {name: previous_label_or_app_version, var: previous_label_or_app_version}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_version: $app_version, client_unique_id: $client_unique_id, deployment_key: $deployment_key, label: $label, previous_deployment_key: $previous_deployment_key, previous_label_or_app_version: $previous_label_or_app_version, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report download of specified release
#
# POST /v0.1/public/codepush/report_status/download
# operationId: codePushAcquisition_updateDownloadStatus
export def "code-push-acquisition-update-download-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-version: string
  --client-unique-id: string
  deployment_key: string
  --label: string
  --previous-deployment-key: string
  --previous-label-or-app-version: string
  --status: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/public/codepush/report_status/download"
    body: {content_type: "application/json", kind: json, fields: [{name: app_version, var: app_version}, {name: client_unique_id, var: client_unique_id}, {name: deployment_key, var: deployment_key}, {name: label, var: label}, {name: previous_deployment_key, var: previous_deployment_key}, {name: previous_label_or_app_version, var: previous_label_or_app_version}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_version: $app_version, client_unique_id: $client_unique_id, deployment_key: $deployment_key, label: $label, previous_deployment_key: $previous_deployment_key, previous_label_or_app_version: $previous_label_or_app_version, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the acquisition service status to the caller
#
# GET /v0.1/public/codepush/status
# Returns: record<code: string, message: string>
# operationId: codePushAcquisition_getAcquisitionStatus
export def "code-push-acquisition-get-acquisition-status" [
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
    path: "/v0.1/public/codepush/status"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check for updates
#
# GET /v0.1/public/codepush/update_check
# Returns: record<update_info: record<description: string, is_disabled: bool, is_mandatory: bool, rollout: int, target_binary_range: string, download_url: string, is_available: bool, label: string, package_hash: string, package_size: float, should_run_binary_version: bool, update_app_version: bool>>
# operationId: codePushAcquisition_updateCheck
export def "code-push-acquisition-update-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-key: string # required
  --app-version: string # required
  --package-hash: string
  --label: string
  --client-unique-id: string
  --is-companion: oneof<nothing, bool>
  --previous-label-or-app-version: string
  --previous-deployment-key: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/public/codepush/update_check"
    query: [{name: deployment_key, var: deployment_key, required: true}, {name: app_version, var: app_version, required: true}, {name: package_hash, var: package_hash}, {name: label, var: label}, {name: client_unique_id, var: client_unique_id}, {name: is_companion, var: is_companion}, {name: previous_label_or_app_version, var: previous_label_or_app_version}, {name: previous_deployment_key, var: previous_deployment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    deployment_key: $deployment_key, app_version: $app_version, package_hash: $package_hash, label: $label, client_unique_id: $client_unique_id, is_companion: $is_companion, previous_label_or_app_version: $previous_label_or_app_version, previous_deployment_key: $previous_deployment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Public webhook sink
#
# POST /v0.1/public/hooks
# operationId: builds_webhook
export def "builds-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/public/hooks"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a release with 'latest' for the given public group.
#
# GET /v0.1/public/sdk/apps/{app_secret}/distribution_groups/{distribution_group_id}/releases/latest
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestByPublicDistributionGroup
export def "releases-get-latest-by-public-distribution-group" [
  app_secret: string
  distribution_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-install-page: oneof<nothing, bool> # The check if the request is from Install page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/public/sdk/apps/{app_secret}/distribution_groups/{distribution_group_id}/releases/latest"
    path_params: [{name: app_secret, var: app_secret}, {name: distribution_group_id, var: distribution_group_id}]
    query: [{name: is_install_page, var: is_install_page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret, distribution_group_id: $distribution_group_id, is_install_page: $is_install_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest public release for the given app.
#
# GET /v0.1/public/sdk/apps/{app_secret}/releases/latest
# DEPRECATED
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestPublicRelease
@deprecated
export def "releases-get-latest-public-release" [
  app_secret: string
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
    path: "/v0.1/public/sdk/apps/{app_secret}/releases/latest"
    path_params: [{name: app_secret, var: app_secret}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all public distribution groups that a given release has been distributed to
#
# GET /v0.1/public/sdk/apps/{app_secret}/releases/{release_hash}/public_distribution_groups
# Returns: table<id: string>
# operationId: releases_getPublicGroupsForReleaseByHash
export def "releases-get-public-groups-for-release-by-hash" [
  app_secret: string
  release_hash: string
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
    path: "/v0.1/public/sdk/apps/{app_secret}/releases/{release_hash}/public_distribution_groups"
    path_params: [{name: app_secret, var: app_secret}, {name: release_hash, var: release_hash}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret, release_hash: $release_hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the sparkle feed of the releases that are distributed to all the public distribution groups.
#
# GET /v0.1/public/sparkle/apps/{app_secret}
# operationId: releases_getSparkleFeed
export def "releases-get-sparkle-feed" [
  app_secret: string
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
    path: "/v0.1/public/sparkle/apps/{app_secret}"
    path_params: [{name: app_secret, var: app_secret}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest release distributed to a private group the given user is a member of for the given app.
#
# GET /v0.1/sdk/apps/{app_secret}/releases/private/latest
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestPrivateRelease
export def "releases-get-latest-private-release" [
  app_secret: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # When passing `udid` in the query string, a provisioning check for the given device ID will be done. Will be ignored for non-iOS platforms.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/sdk/apps/{app_secret}/releases/private/latest"
    path_params: [{name: app_secret, var: app_secret}]
    query: [{name: udid, var: udid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret, udid: $udid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If 'latest' is not specified then it will return the specified release if it's enabled. If 'latest' is specified, regardless of whether a release hash is provided, the latest enabled release is returned.
#
# GET /v0.1/sdk/apps/{app_secret}/releases/{release_hash}
# Returns: record<android_min_api_level: string, app_display_name: string, app_icon_url: string, app_name: string, app_os: string, build: record<branch_name: string, commit_hash: string, commit_message: string>, bundle_identifier: string, can_resign: bool, destination_type: string, destinations: table<id: string, name: string, is_latest: bool, publishing_status: string, type: string, destination_type: string, display_name: string>, device_family: string, distribution_groups: table<id: string, name: string>, distribution_stores: table<id: string, name: string, publishing_status: string, type: string>, download_url: string, enabled: bool, fingerprint: string, id: int, install_url: string, is_external_build: bool, is_provisioning_profile_syncing: bool, is_udid_provisioned: bool, min_os: string, origin: string, package_hashes: list<string>, provisioning_profile_expiry_date: string, provisioning_profile_name: string, provisioning_profile_type: string, release_notes: string, secondary_download_url: string, short_version: string, size: int, status: string, uploaded_at: string, version: string>
# operationId: releases_getLatestByHash
export def "releases-get-latest-by-hash" [
  app_secret: string
  release_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --udid: string # When passing `udid` in the query string, a provisioning check for the given device ID will be done. Will be ignored for non-iOS platforms.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/sdk/apps/{app_secret}/releases/{release_hash}"
    path_params: [{name: app_secret, var: app_secret}, {name: release_hash, var: release_hash}]
    query: [{name: udid, var: udid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    app_secret: $app_secret, release_hash: $release_hash, udid: $udid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the user profile data
#
# GET /v0.1/user
# Returns: record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>
# operationId: users_get
export def "users-get" [
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
    path: "/v0.1/user"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the user profile and returns the updated user data
#
# PATCH /v0.1/user
# Returns: record<avatar_url: string, can_change_password: bool, display_name: string, email: string, id: string, name: string, origin: string, permissions: list<string>>
# operationId: users_update
export def "users-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: string # The full name of the user. Might for example be first and last name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v0.1/user"
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    display_name: $display_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all devices associated with the given user.
#
# GET /v0.1/user/devices
# Returns: table<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>
# operationId: devices_userDevicesList
export def "devices-user-devices-list" [
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
    path: "/v0.1/user/devices"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an existing device from a user
#
# DELETE /v0.1/user/devices/{device_udid}
# operationId: devices_removeUserDevice
export def "devices-remove-user-device" [
  device_udid: string
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
    path: "/v0.1/user/devices/{device_udid}"
    path_params: [{name: device_udid, var: device_udid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    device_udid: $device_udid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the device details.
#
# GET /v0.1/user/devices/{device_udid}
# Returns: record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>
# operationId: devices_deviceDetails
export def "devices-device-details" [
  device_udid: string
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
    path: "/v0.1/user/devices/{device_udid}"
    path_params: [{name: device_udid, var: device_udid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    device_udid: $device_udid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v0.1/user/dsr/delete
#
# Returns: record<createdAt: string, token: string>
# operationId: DataSubjectRight_DeleteRequest
export def "data-subject-right-delete-request" [
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
    path: "/v0.1/user/dsr/delete"
    accept: ["application/json"]
    ok: [202]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v0.1/user/dsr/delete/{token}
#
# Returns: record<message: string, sasUrl: string, sasUrlExpired: bool, status: string>
# operationId: DataSubjectRight_DeleteStatusRequest
export def "data-subject-right-delete-status-request" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email used for delete with x-authz-bypass headers (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v0.1/user/dsr/delete/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: email, var: email, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    token_arg: $token_arg, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v0.1/user/dsr/delete/{token}/cancel
#
# Returns: record<createdAt: string, token: string>
# operationId: DataSubjectRight_CancelDeleteRequest
export def "data-subject-right-cancel-delete-request" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email used for cancel delete with x-authz-bypass headers
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/user/dsr/delete/{token}/cancel"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-api-token
  } {
    token_arg: $token_arg, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v0.1/user/dsr/export
#
# Returns: record<createdAt: string, token: string>
# operationId: DataSubjectRight_ExportRequest
export def "data-subject-right-export-request" [
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
    path: "/v0.1/user/dsr/export"
    accept: ["application/json"]
    ok: [202]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v0.1/user/dsr/export/{token}
#
# Returns: record<message: string, sasUrl: string, sasUrlExpired: bool, status: string>
# operationId: DataSubjectRight_ExportStatusRequest
export def "data-subject-right-export-status-request" [
  token_arg: string
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
    path: "/v0.1/user/dsr/export/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v0.1/user/dsr/export/{token}/cancel
#
# Returns: record<createdAt: string, token: string>
# operationId: DataSubjectRight_CancelExportRequest
export def "data-subject-right-cancel-export-request" [
  token_arg: string
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
    path: "/v0.1/user/dsr/export/{token}/cancel"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [202]
    auth: x-api-token
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all service connections of the service type for GDPR export.
#
# GET /v0.1/user/export/serviceConnections
# Returns: table<credentialType: string, displayName: string, serviceType: string>
# operationId: sharedconnection_Connections
export def "sharedconnection-connections" [
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
    path: "/v0.1/user/export/serviceConnections"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts a pending invitation for the specified user
#
# POST /v0.1/user/invitations/apps/{invitation_token}/accept
# operationId: appInvitations_accept
export def "app-invitations-accept" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/user/invitations/apps/{invitation_token}/accept"
    path_params: [{name: invitation_token, var: invitation_token}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    invitation_token: $invitation_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects a pending invitation for the specified user
#
# POST /v0.1/user/invitations/apps/{invitation_token}/reject
# operationId: appInvitations_reject
export def "app-invitations-reject" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/user/invitations/apps/{invitation_token}/reject"
    path_params: [{name: invitation_token, var: invitation_token}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    invitation_token: $invitation_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts all pending invitations to distribution groups for the specified user
#
# POST /v0.1/user/invitations/distribution_groups/accept
# operationId: distributionGroupInvitations_acceptAll
export def "distribution-group-invitations-accept-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/user/invitations/distribution_groups/accept"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts a pending organization invitation for the specified user
#
# POST /v0.1/user/invitations/orgs/{invitation_token}/accept
# operationId: orgInvitations_accept
export def "org-invitations-accept" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/user/invitations/orgs/{invitation_token}/accept"
    path_params: [{name: invitation_token, var: invitation_token}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    invitation_token: $invitation_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects a pending organization invitation
#
# POST /v0.1/user/invitations/orgs/{invitation_token}/reject
# operationId: orgInvitations_reject
export def "org-invitations-reject" [
  invitation_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/v0.1/user/invitations/orgs/{invitation_token}/reject"
    path_params: [{name: invitation_token, var: invitation_token}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: x-api-token
  } {
    invitation_token: $invitation_token, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v0.1/user/metadata/optimizely
#
# Returns: record<metadata: record, userId: string>
# operationId: Users_getUserMetadata
export def "users-get-user-metadata" [
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
    path: "/v0.1/user/metadata/optimizely"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Default email notification settings for the user
#
# GET /v0.1/user/notifications/emailSettings
# Returns: record<request_id: string, eTag: string, enabled: bool, settings: table<default_value: string, event_type: string, value: string>, userId: string>
# operationId: notifications_getUserEmailSettings
export def "notifications-get-user-email-settings" [
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
    path: "/v0.1/user/notifications/emailSettings"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a user for an existing device
#
# POST /v0.1/users/{user_id}/devices/register
# Returns: record<device_name: string, full_device_name: string, imei: string, model: string, os_build: string, os_version: string, owner_id: string, registered_at: string, serial: string, status: string, udid: string>
# operationId: devices_registerUserForDevice
export def "devices-register-user-for-device" [
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
  --imei: string # The device's International Mobile Equipment Identity number. Always empty or undefined at present.
  model: string # The model identifier of the device, in the format iDeviceM,N
  --os-build: string # The build number of the last known OS version running on the device
  --os-version: string # The last known OS version running on the device
  --owner-id: string # The user ID of the device owner.
  --serial: string # The device's serial number. Always empty or undefined at present.
  udid: string # The Unique Device IDentifier of the device
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v0.1/users/{user_id}/devices/register"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: imei, var: imei}, {name: model, var: model}, {name: os_build, var: os_build}, {name: os_version, var: os_version}, {name: owner_id, var: owner_id}, {name: serial, var: serial}, {name: udid, var: udid}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-token
  } {
    user_id: $user_id, imei: $imei, model: $model, os_build: $os_build, os_version: $os_version, owner_id: $owner_id, serial: $serial, udid: $udid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
