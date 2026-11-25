# Auto-generated client for AppVeyor REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/appveyor.com/1.0.0/swagger.json
# Auth: --token flag or $env.APPVEYOR_REST_API_TOKEN

const CLIENT = {
  base_url: "https://ci.appveyor.com/api"
  token_env_var: "APPVEYOR_REST_API_TOKEN"
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

def base-url-completer [] { ["https://ci.appveyor.com/api"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def provider-completer [] { ["Agent" "AzureBlob" "AzureCS" "AzureWebJob" "BinTray" "FTP" "GitHub" "NuGet" "S3" "SqlDatabase" "WebDeploy" "Webhook"] }
def projects-mode-completer [] { ["0" "1" "2"] }
def repository-authentication-completer [] { ["credentials" "ssh"] }
def repository-provider-completer [] { ["bitBucket" "git" "gitHub" "gitLab" "kiln" "mercurial" "stash" "subversion" "vso"] }
def repository-scm-completer [] { ["git" "mercurial" "subversion"] }
def repository-type-completer [] { ["bitBucket" "git" "gitHub" "gitLab" "kiln" "mercurial" "stash" "subversion" "vso"] }
def badge-repo-provider-completer [] { ["bitBucket" "gitHub"] }
def accept-completer-1 [] { ["image/png" "image/svg+xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    encrypt-value: "string"
    get-build-artifacts: "table<created: string, fileName: string, name: string, size: int, type: string, url: string>"
    get-build-artifact: "binary"
    get-build-log: "binary"
    start-build: "record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>"
    re-run-build: "record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>"
    get-collaborators: "table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>"
    get-collaborator: "record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>"
    start-deployment: "record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, messagesCount: int>>"
    get-deployment: "record<deployment: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record, tags: string>, jobs: list<record>>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-environments: "table<deploymentEnvironmentId: int, name: string, provider: string>"
    add-environment: "record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>"
    update-environment: "record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>"
    get-environment-deployments: "record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, project: record>, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>>"
    get-environment-settings: "record<environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string, environmentAccessKey: string, projects: list<record>, selectedProjects: list<int>, settings: record<environmentVariables: list, notifications: list, providerSettings: list>>>"
    get-projects: "table<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>"
    add-project: "record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, skipBranchesWithoutAppveyorYml: bool, tags: string>"
    get-public-project-status-badge: "binary"
    get-project-status-badge: "binary"
    get-project-branch-status-badge: "binary"
    get-project-last-build: "record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-project-artifact: "binary"
    get-project-last-build-branch: "record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-project-build-by-version: "record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-project-deployments: "record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, environment: record>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-project-history: "record<builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>"
    get-project-settings: "record<buildClouds: table<value: string>, defaultImageName: string, images: table<buildCloudName: string, buildWorkerImageId: int, name: string, osType: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>, settings: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string, buildPriority: int, configuration: record<afterBuildScripts: list, afterDeployScripts: list, afterTestScripts: list, artifacts: list, assemblyFileVersionFormat: string, assemblyInfoFile: string, assemblyInformationalVersionFormat: string, assemblyVersionFormat: string, beforeBuildScripts: list, beforeDeployScripts: list, beforePackageScripts: list, beforeTestScripts: list, branchesMode: string, buildCloud: list, buildMode: string, buildScripts: list, cacheEntries: list, cloneDepth: int, cloneFolder: string, cloneScripts: list, configuration: list, configureNuGetAccountSource: bool, configureNuGetProjectSource: bool, deployMode: string, deployScripts: list, deployments: list, disableNuGetPublishForOctopusPackages: bool, disableNuGetPublishOnPullRequests: bool, doNotIncrementBuildNumberOnPullRequests: bool, dotnetCsprojAssemblyVersionFormat: string, dotnetCsprojFile: string, dotnetCsprojFileVersionFormat: string, dotnetCsprojInformationalVersionFormat: string, dotnetCsprojPackageVersionFormat: string, dotnetCsprojVersionFormat: string, environmentVariables: list, environmentVariablesMatrix: list, excludeBranches: list, forceHttpsClone: bool, hostsEntries: list, hotFixScripts: list, includeBranches: list, includeNuGetReferences: bool, initScripts: list, installScripts: list, matrixAllowFailures: list, matrixExcept: list, matrixExclude: list, matrixFastFinish: bool, matrixOnly: list, maxJobs: int, msBuildInParallel: bool, msBuildProjectFileName: string, msBuildVerbosity: string, notifications: list, onBuildErrorScripts: list, onBuildFinishScripts: list, onBuildSuccessScripts: list, onlyCommitsFiles: list, operatingSystem: list, packageAspNetCoreProjects: bool, packageAzureCloudServiceProjects: bool, packageDotnetConsoleProjects: bool, packageNuGetProjects: bool, packageNuGetSymbols: bool, packageWebApplicationProjects: bool, packageWebApplicationProjectsBeanstalk: bool, packageWebApplicationProjectsOctopus: bool, packageWebApplicationProjectsXCopy: bool, patchAssemblyInfo: bool, patchDotnetCsproj: bool, platform: list, services: list, shallowClone: bool, skipBranchWithPullRequests: bool, skipCommitsFiles: list, skipNonTags: bool, skipTags: bool, stacks: list, testAssemblies: list, testCategories: list, testCategoriesMatrix: list, testCategoriesMode: string, testMode: string, testScripts: list, xamarinRegisterAndroidProduct: bool, xamarinRegisterIosProduct: bool>, customYmlName: string, ignoreAppveyorYml: bool, nextBuildNumber: int, repositoryAuthentication: string, repositoryUsername: string, scheduleCrontabExpression: string, sshPublicKey: string, statusBadgeId: string, versionFormat: string, webhookId: string, webhookUrl: string>>"
    get-project-environment-variables: "table<name: string, value: record<isEncrypted: bool, value: string>>"
    get-project-settings-yaml: "string"
    get-roles: "table<created: string, updated: string, isSystem: bool, name: string, roleId: int>"
    add-role: "record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>"
    update-role: "record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>"
    get-role: "record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>"
    join-account: "record<accounts: table<created: string, updated: string, accountId: int, allowCustomBuildEnvironment: bool, blocked: bool, featureFlags: string, gitHubPlan: bool, gitHubPlanOrg: string, isCollaborator: bool, isEnterprisePlan: bool, isOwner: bool, manualPayments: bool, name: string, permissions: list, planEnd: string, planId: string, planStart: string, planStatus: string, roleId: int, roleName: string, timeZoneId: string, unpaid: bool, unverified: bool>, setupRequired: bool, twoFactorAuthRequired: bool, user: record<created: string, updated: string, bitBucketUsername: string, email: string, fullName: string, gitHubUsername: string, gitLabUserId: string, gravatarHash: string, pageSize: int, twoFactorAuthEnabled: bool, userId: int, vsoUsername: string>>"
    get-users: "table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>"
    get-user-invitations: "table<accountId: int, accountName: string, created: string, email: string, roleId: int, roleName: string, userInvitationId: string>"
    get-user: "record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["encrypt-value" "get-build-artifacts" "get-build-artifact" "get-build-log" "start-build" "re-run-build" "cancel-build" "get-collaborators" "update-collaborator" "delete-collaborator" "get-collaborator" "start-deployment" "cancel-deployment" "get-deployment" "get-environments" "add-environment" "update-environment" "delete-environment" "get-environment-deployments" "get-environment-settings" "get-projects" "add-project" "update-project" "get-public-project-status-badge" "get-project-status-badge" "get-project-branch-status-badge" "delete-project" "get-project-last-build" "get-project-artifact" "get-project-last-build-branch" "get-project-build-by-version" "delete-project-build-cache" "get-project-deployments" "get-project-history" "get-project-settings" "update-project-build-number" "get-project-environment-variables" "update-project-environment-variables" "get-project-settings-yaml" "update-project-settings-yaml" "get-roles" "add-role" "update-role" "delete-role" "get-role" "join-account" "get-users" "update-user" "get-user-invitations" "invite-user" "cancel-user-invitation" "delete-user" "get-user" "commands"] | sort) } | get name | first)
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

# Encrypt a value for use in StoredValue.
#
# POST /account/encrypt
# Returns: string
# operationId: encryptValue
export def "encrypt-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plain-value: string # default: ""
]: any -> any {
  $in | http-request {
    method: post
    path: "/account/encrypt"
    body: {content_type: "application/json", kind: json, fields: [{name: plainValue, var: plain_value}]}
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    plain_value: $plain_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get build artifacts
#
# GET /buildjobs/{jobId}/artifacts
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# Returns: table<created: string, fileName: string, name: string, size: int, type: string, url: string>
# operationId: getBuildArtifacts
export def "get-build-artifacts" [
  job_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/buildjobs/{jobId}/artifacts"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: none
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Download build artifact
#
# GET /buildjobs/{jobId}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/api/samples/download-artifacts-advanced-ps/
# Returns: binary
# operationId: getBuildArtifact
export def "get-build-artifact" [
  job_id: string
  artifact_file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/buildjobs/{jobId}/artifacts/{artifactFileName}"
    path_params: [{name: jobId, var: job_id}, {name: artifactFileName, var: artifact_file_name}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: none
  } {
    job_id: $job_id, artifact_file_name: $artifact_file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download build log
#
# GET /buildjobs/{jobId}/log
# Docs: https://www.appveyor.com/docs/api/projects-builds/#download-build-log
# Returns: binary
# operationId: getBuildLog
export def "get-build-log" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/buildjobs/{jobId}/log"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: none
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start build of branch most recent commit
#
# POST /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#start-build-of-branch-most-recent-commit
# Returns: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>
# operationId: startBuild
export def "start-build" [
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
  account_name: string
  --branch: string
  --commit-id: string
  --environment-variables: record
  project_slug: string
  --pull-request-id: int # Can not be used with `branch` or `commitId`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/builds"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: branch, var: branch}, {name: commitId, var: commit_id}, {name: environmentVariables, var: environment_variables}, {name: projectSlug, var: project_slug}, {name: pullRequestId, var: pull_request_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, branch: $branch, commit_id: $commit_id, environment_variables: $environment_variables, project_slug: $project_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Re-run build
#
# PUT /builds
# Docs: https://www.appveyor.com/docs/api/projects-builds/#re-run-build
# Returns: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, allowFailure: bool, artifactsCount: int, compilationErrorsCount: int, compilationMessagesCount: int, compilationWarningsCount: int, failedTestsCount: int, messagesCount: int, osType: string, passedTestsCount: int, testsCount: int>, messageExtended: string, messages: table<category: string, created: string, message: string>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>
# operationId: reRunBuild
export def "re-run-build" [
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
  build_id: int
  --re-run-incomplete: oneof<nothing, bool> # Set `reRunIncomplete` set to `false` (default value) for full build re-run. Set it set to `true` to rerun only failed or cancelled jobs in multijob build.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/builds"
    body: {content_type: "application/json", kind: json, fields: [{name: buildId, var: build_id}, {name: reRunIncomplete, var: re_run_incomplete}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    build_id: $build_id, re_run_incomplete: $re_run_incomplete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel build
#
# DELETE /builds/{accountName}/{projectSlug}/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#cancel-build
# operationId: cancelBuild
export def "cancel-build" [
  account_name: string
  project_slug: string
  build_version: string
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
    method: delete
    path: "/builds/{accountName}/{projectSlug}/{buildVersion}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}, {name: buildVersion, var: build_version}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug, build_version: $build_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get collaborators
#
# GET /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborators
# Returns: table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>
# operationId: getCollaborators
export def "get-collaborators" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collaborators"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update collaborator
#
# PUT /collaborators
# Docs: https://www.appveyor.com/docs/api/team/#update-collaborator
# operationId: updateCollaborator
export def "update-collaborator" [
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
  role_id: int
  user_id: int
]: any -> any {
  $in | http-request {
    method: put
    path: "/collaborators"
    body: {content_type: "application/json", kind: json, fields: [{name: roleId, var: role_id}, {name: userId, var: user_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    role_id: $role_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete collaborator
#
# DELETE /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-collaborator
# operationId: deleteCollaborator
export def "delete-collaborator" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/collaborators/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get collaborator
#
# GET /collaborators/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-collaborator
# Returns: record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>
# operationId: getCollaborator
export def "get-collaborator" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collaborators/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Start deployment
#
# POST /deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#start-deployment
# Returns: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>, jobs: table<created: string, updated: string, finished: string, jobId: string, name: string, started: string, status: string, messagesCount: int>>
# operationId: startDeployment
export def "start-deployment" [
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
  account_name: string
  --build-job-id: string # Optional job id with artifacts if build contains multiple jobs.
  build_version: string # Build to deploy
  environment_name: string
  --environment-variables: record
  project_slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deployments"
    body: {content_type: "application/json", kind: json, fields: [{name: accountName, var: account_name}, {name: buildJobId, var: build_job_id}, {name: buildVersion, var: build_version}, {name: environmentName, var: environment_name}, {name: environmentVariables, var: environment_variables}, {name: projectSlug, var: project_slug}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, build_job_id: $build_job_id, build_version: $build_version, environment_name: $environment_name, environment_variables: $environment_variables, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel deployment
#
# PUT /deployments/stop
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#cancel-deployment
# operationId: cancelDeployment
export def "cancel-deployment" [
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
  deployment_id: int
]: any -> any {
  $in | http-request {
    method: put
    path: "/deployments/stop"
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get deployment
#
# GET /deployments/{deploymentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-deployment
# Returns: record<deployment: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, deploymentId: int, finished: string, started: string, status: string, created: string, updated: string, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record, tags: string>, jobs: list<record>>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getDeployment
export def "get-deployment" [
  deployment_id: int
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
    path: "/deployments/{deploymentId}"
    path_params: [{name: deploymentId, var: deployment_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get environments
#
# GET /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environments
# Returns: table<deploymentEnvironmentId: int, name: string, provider: string>
# operationId: getEnvironments
export def "get-environments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/environments"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add environment
#
# POST /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#add-environment
# Returns: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>
# operationId: addEnvironment
export def "add-environment" [
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
  name: string
  provider: string@provider-completer
  settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/environments"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: provider, var: provider}, {name: settings, var: settings}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, provider: $provider, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update environment
#
# PUT /environments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#update-environment
# Returns: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, tags: string, environmentAccessKey: string, projects: table<isSelected: bool, name: string, projectId: int>, selectedProjects: list<int>, settings: record<environmentVariables: list<record>, notifications: list<record>, providerSettings: list<record>>>
# operationId: updateEnvironment
export def "update-environment" [
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
  --deployment-environment-id: int
  --name: string
  --provider: string@provider-completer
  --account-id: int
  --projects-mode: int@projects-mode-completer # Project selection mode for deployment environments.
  --security-descriptor: record # shape: {accessRightDefinitions?: list, roleAces?: list}
  --tags: string # Comma-separated list of environment tags for dynamic grouping. Appears that any input is accepted. The returned value only contains case-preserving but insensitive unique values where spaces around "," are removed but otherwise preserved. Empty values and items are allowed.
  --environment-access-key: string
  --projects: list # Projects available for selection in UI. Only present in response from getEnvironmentSettings. — item shape: {isSelected: bool, name: string, projectId: int}
  --selected-projects: list<int> # Project IDs of selected projects
  --settings: record # shape: {environmentVariables?: list, notifications?: list, providerSettings?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/environments"
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentEnvironmentId, var: deployment_environment_id}, {name: name, var: name}, {name: provider, var: provider}, {name: accountId, var: account_id}, {name: projectsMode, var: projects_mode}, {name: securityDescriptor, var: security_descriptor}, {name: tags, var: tags}, {name: environmentAccessKey, var: environment_access_key}, {name: projects, var: projects}, {name: selectedProjects, var: selected_projects}, {name: settings, var: settings}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id, name: $name, provider: $provider, account_id: $account_id, projects_mode: $projects_mode, security_descriptor: $security_descriptor, tags: $tags, environment_access_key: $environment_access_key, projects: $projects, selected_projects: $selected_projects, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete environment
#
# DELETE /environments/{deploymentEnvironmentId}
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#delete-environment
# operationId: deleteEnvironment
export def "delete-environment" [
  deployment_environment_id: int
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
    method: delete
    path: "/environments/{deploymentEnvironmentId}"
    path_params: [{name: deploymentEnvironmentId, var: deployment_environment_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get environment deployments
#
# GET /environments/{deploymentEnvironmentId}/deployments
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-deployments
# Returns: record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, project: record>, environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string>>
# operationId: getEnvironmentDeployments
export def "get-environment-deployments" [
  deployment_environment_id: int
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
    path: "/environments/{deploymentEnvironmentId}/deployments"
    path_params: [{name: deploymentEnvironmentId, var: deployment_environment_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get environment settings
#
# GET /environments/{deploymentEnvironmentId}/settings
# Docs: https://www.appveyor.com/docs/api/environments-deployments/#get-environment-settings
# Returns: record<environment: record<deploymentEnvironmentId: int, name: string, provider: string, created: string, updated: string, accountId: int, projectsMode: int, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, tags: string, environmentAccessKey: string, projects: list<record>, selectedProjects: list<int>, settings: record<environmentVariables: list, notifications: list, providerSettings: list>>>
# operationId: getEnvironmentSettings
export def "get-environment-settings" [
  deployment_environment_id: int
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
    path: "/environments/{deploymentEnvironmentId}/settings"
    path_params: [{name: deploymentEnvironmentId, var: deployment_environment_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get projects
#
# GET /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-projects
# Returns: table<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>
# operationId: getProjects
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add project
#
# POST /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#add-project
# Returns: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list<record>, roleAces: list<record>>, skipBranchesWithoutAppveyorYml: bool, tags: string>
# operationId: addProject
export def "add-project" [
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
  --repository-authentication: string@repository-authentication-completer
  repository_name: string # URL when repositoryProvider is git, mercurial, subversion username/project when repositoryProvider is gitHub
  --repository-password: string # Required if repositoryAuthentication is credentials (format: password)
  repository_provider: string@repository-provider-completer
  --repository-username: string # Required if repositoryAuthentication is credentials
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: repositoryAuthentication, var: repository_authentication}, {name: repositoryName, var: repository_name}, {name: repositoryPassword, var: repository_password}, {name: repositoryProvider, var: repository_provider}, {name: repositoryUsername, var: repository_username}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    repository_authentication: $repository_authentication, repository_name: $repository_name, repository_password: $repository_password, repository_provider: $repository_provider, repository_username: $repository_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update project
#
# PUT /projects
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project
# operationId: updateProject
export def "update-project" [
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
  --name: string
  project_id: int
  --always-build-closed-pull-requests: oneof<nothing, bool>
  --current-build-id: int
  --disable-pull-request-webhooks: oneof<nothing, bool>
  --disable-push-webhooks: oneof<nothing, bool>
  --enable-deployment-in-pull-requests: oneof<nothing, bool>
  --enable-secure-variables-in-pull-requests: oneof<nothing, bool>
  --enable-secure-variables-in-pull-requests-from-same-repo: oneof<nothing, bool>
  --is-git-hub-app: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --nu-get-feed: record # shape: {accountId?: int, id?: string, isPrivateProject?: bool, name?: string, nuGetFeedId?: int, projectId?: int, publishingEnabled?: bool}
  --repository-branch: string # Not present in response from addProject.
  repository_name: string
  --repository-scm: string@repository-scm-completer
  --repository-type: string@repository-type-completer
  --rolling-builds: oneof<nothing, bool>
  --rolling-builds-do-not-cancel-running-builds: oneof<nothing, bool>
  --rolling-builds-only-for-pull-requests: oneof<nothing, bool>
  --save-build-cache-in-pull-requests: oneof<nothing, bool>
  --security-descriptor: record # shape: {accessRightDefinitions?: list, roleAces?: list}
  --skip-branches-without-appveyor-yml: oneof<nothing, bool>
  --tags: string # Comma-separated list of project tags for dynamic grouping. Appears that any input is accepted. The returned value only contains case-preserving but insensitive unique values where spaces around "," are removed but otherwise preserved. Empty values and items are allowed.
  --build-priority: int
  configuration: record # shape: {afterBuildScripts?: list, afterDeployScripts?: list, afterTestScripts?: list, artifacts?: list, assemblyFileVersionFormat?: string, assemblyInfoFile?: string, assemblyInformationalVersionFormat?: string, assemblyVersionFormat?: string, beforeBuildScripts?: list, beforeDeployScripts?: list, beforePackageScripts?: list, beforeTestScripts?: list, branchesMode?: "exclude"|"include", buildCloud?: list, buildMode?: "msbuild"|"none"|"script", buildScripts?: list, cacheEntries?: list, cloneDepth?: int, ... (69 more fields)}
  --custom-yml-name: string
  --ignore-appveyor-yml: oneof<nothing, bool>
  --next-build-number: int
  --repository-authentication: string@repository-authentication-completer
  --repository-username: string
  --schedule-crontab-expression: string # Build schedule as an NCrontab Expression. See https://github.com/atifaziz/NCrontab/wiki/Crontab-Expression
  --ssh-public-key: string
  --status-badge-id: string
  version_format: string
  --webhook-id: string
  --webhook-url: string # format: uri
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: projectId, var: project_id}, {name: alwaysBuildClosedPullRequests, var: always_build_closed_pull_requests}, {name: currentBuildId, var: current_build_id}, {name: disablePullRequestWebhooks, var: disable_pull_request_webhooks}, {name: disablePushWebhooks, var: disable_push_webhooks}, {name: enableDeploymentInPullRequests, var: enable_deployment_in_pull_requests}, {name: enableSecureVariablesInPullRequests, var: enable_secure_variables_in_pull_requests}, {name: enableSecureVariablesInPullRequestsFromSameRepo, var: enable_secure_variables_in_pull_requests_from_same_repo}, {name: isGitHubApp, var: is_git_hub_app}, {name: isPrivate, var: is_private}, {name: nuGetFeed, var: nu_get_feed}, {name: repositoryBranch, var: repository_branch}, {name: repositoryName, var: repository_name}, {name: repositoryScm, var: repository_scm}, {name: repositoryType, var: repository_type}, {name: rollingBuilds, var: rolling_builds}, {name: rollingBuildsDoNotCancelRunningBuilds, var: rolling_builds_do_not_cancel_running_builds}, {name: rollingBuildsOnlyForPullRequests, var: rolling_builds_only_for_pull_requests}, {name: saveBuildCacheInPullRequests, var: save_build_cache_in_pull_requests}, {name: securityDescriptor, var: security_descriptor}, {name: skipBranchesWithoutAppveyorYml, var: skip_branches_without_appveyor_yml}, {name: tags, var: tags}, {name: buildPriority, var: build_priority}, {name: configuration, var: configuration}, {name: customYmlName, var: custom_yml_name}, {name: ignoreAppveyorYml, var: ignore_appveyor_yml}, {name: nextBuildNumber, var: next_build_number}, {name: repositoryAuthentication, var: repository_authentication}, {name: repositoryUsername, var: repository_username}, {name: scheduleCrontabExpression, var: schedule_crontab_expression}, {name: sshPublicKey, var: ssh_public_key}, {name: statusBadgeId, var: status_badge_id}, {name: versionFormat, var: version_format}, {name: webhookId, var: webhook_id}, {name: webhookUrl, var: webhook_url}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    name: $name, project_id: $project_id, always_build_closed_pull_requests: $always_build_closed_pull_requests, current_build_id: $current_build_id, disable_pull_request_webhooks: $disable_pull_request_webhooks, disable_push_webhooks: $disable_push_webhooks, enable_deployment_in_pull_requests: $enable_deployment_in_pull_requests, enable_secure_variables_in_pull_requests: $enable_secure_variables_in_pull_requests, enable_secure_variables_in_pull_requests_from_same_repo: $enable_secure_variables_in_pull_requests_from_same_repo, is_git_hub_app: $is_git_hub_app, is_private: $is_private, nu_get_feed: $nu_get_feed, repository_branch: $repository_branch, repository_name: $repository_name, repository_scm: $repository_scm, repository_type: $repository_type, rolling_builds: $rolling_builds, rolling_builds_do_not_cancel_running_builds: $rolling_builds_do_not_cancel_running_builds, rolling_builds_only_for_pull_requests: $rolling_builds_only_for_pull_requests, save_build_cache_in_pull_requests: $save_build_cache_in_pull_requests, security_descriptor: $security_descriptor, skip_branches_without_appveyor_yml: $skip_branches_without_appveyor_yml, tags: $tags, build_priority: $build_priority, configuration: $configuration, custom_yml_name: $custom_yml_name, ignore_appveyor_yml: $ignore_appveyor_yml, next_build_number: $next_build_number, repository_authentication: $repository_authentication, repository_username: $repository_username, schedule_crontab_expression: $schedule_crontab_expression, ssh_public_key: $ssh_public_key, status_badge_id: $status_badge_id, version_format: $version_format, webhook_id: $webhook_id, webhook_url: $webhook_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get status badge image for a project with a public repository
#
# GET /projects/status/{badgeRepoProvider}/{repoAccountName}/{repoSlug}
# Docs: https://www.appveyor.com/docs/status-badges/
# Returns: binary
# operationId: getPublicProjectStatusBadge
export def "get-public-project-status-badge" [
  badge_repo_provider: string@badge-repo-provider-completer
  repo_account_name: string
  repo_slug: string
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
  --branch: string # Repository Branch
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/status/{badgeRepoProvider}/{repoAccountName}/{repoSlug}"
    path_params: [{name: badgeRepoProvider, var: badge_repo_provider}, {name: repoAccountName, var: repo_account_name}, {name: repoSlug, var: repo_slug}]
    query: [{name: branch, var: branch}, {name: svg, var: svg}, {name: retina, var: retina}, {name: passingText, var: passing_text}, {name: failingText, var: failing_text}, {name: pendingText, var: pending_text}]
    accept: ["image/svg+xml", "image/png"]
    ok: [200]
    auth: none
  } {
    badge_repo_provider: $badge_repo_provider, repo_account_name: $repo_account_name, repo_slug: $repo_slug, branch: $branch, svg: $svg, retina: $retina, passing_text: $passing_text, failing_text: $failing_text, pending_text: $pending_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project status badge image
#
# GET /projects/status/{statusBadgeId}
# Docs: https://www.appveyor.com/docs/status-badges/
# Returns: binary
# operationId: getProjectStatusBadge
export def "get-project-status-badge" [
  status_badge_id: string
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
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/status/{statusBadgeId}"
    path_params: [{name: statusBadgeId, var: status_badge_id}]
    query: [{name: svg, var: svg}, {name: retina, var: retina}, {name: passingText, var: passing_text}, {name: failingText, var: failing_text}, {name: pendingText, var: pending_text}]
    accept: ["image/svg+xml", "image/png"]
    ok: [200]
    auth: none
  } {
    status_badge_id: $status_badge_id, svg: $svg, retina: $retina, passing_text: $passing_text, failing_text: $failing_text, pending_text: $pending_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project branch status badge image
#
# GET /projects/status/{statusBadgeId}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/status-badges/
# Returns: binary
# operationId: getProjectBranchStatusBadge
export def "get-project-branch-status-badge" [
  status_badge_id: string
  build_branch: string
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
  --svg: oneof<nothing, bool> # Return an SVG image instead of PNG? Exclusive with `retina`. (default: false)
  --retina: oneof<nothing, bool> # Return a larger image suitable for retina displays? Exclusive with `svg`. (default: false)
  --passing-text: string # Text to show in badge when build is passing.
  --failing-text: string # Text to show in badge when build is failing.
  --pending-text: string # Text to show in badge when build is pending.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/status/{statusBadgeId}/branch/{buildBranch}"
    path_params: [{name: statusBadgeId, var: status_badge_id}, {name: buildBranch, var: build_branch}]
    query: [{name: svg, var: svg}, {name: retina, var: retina}, {name: passingText, var: passing_text}, {name: failingText, var: failing_text}, {name: pendingText, var: pending_text}]
    accept: ["image/svg+xml", "image/png"]
    ok: [200]
    auth: none
  } {
    status_badge_id: $status_badge_id, build_branch: $build_branch, svg: $svg, retina: $retina, passing_text: $passing_text, failing_text: $failing_text, pending_text: $pending_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete project
#
# DELETE /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project
# operationId: deleteProject
export def "delete-project" [
  account_name: string
  project_slug: string
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
    method: delete
    path: "/projects/{accountName}/{projectSlug}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project last build
#
# GET /projects/{accountName}/{projectSlug}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-build
# Returns: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getProjectLastBuild
export def "get-project-last-build" [
  account_name: string
  project_slug: string
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
    path: "/projects/{accountName}/{projectSlug}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: none
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get last successful build artifact
#
# GET /projects/{accountName}/{projectSlug}/artifacts/{artifactFileName}
# Docs: https://www.appveyor.com/docs/packaging-artifacts/#permalink-to-the-last-successful-build-artifact
# Returns: binary
# operationId: getProjectArtifact
export def "get-project-artifact" [
  account_name: string
  project_slug: string
  artifact_file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # Repository Branch
  --tag: string # A git (or other VCS) tag
  --job: string # Name of the build job.
  --all: oneof<nothing, bool> # Include not only `successful`, but also jobs with `failed`, and `cancelled` status. (default: false)
  --pr: oneof<nothing, bool> # Include PR builds in the search results? `true` - take artifact from PR builds only; `false` - do not look for artifact in PR builds; default/unspecified - look for artifact in both PR an non-PR builds.
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/{accountName}/{projectSlug}/artifacts/{artifactFileName}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}, {name: artifactFileName, var: artifact_file_name}]
    query: [{name: branch, var: branch}, {name: tag, var: tag}, {name: job, var: job}, {name: all, var: all}, {name: pr, var: pr}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: none
  } {
    account_name: $account_name, project_slug: $project_slug, artifact_file_name: $artifact_file_name, branch: $branch, tag: $tag, job: $job, all: $all, pr: $pr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project last branch build
#
# GET /projects/{accountName}/{projectSlug}/branch/{buildBranch}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-last-branch-build
# Returns: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getProjectLastBuildBranch
export def "get-project-last-build-branch" [
  account_name: string
  project_slug: string
  build_branch: string
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
    path: "/projects/{accountName}/{projectSlug}/branch/{buildBranch}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}, {name: buildBranch, var: build_branch}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: none
  } {
    account_name: $account_name, project_slug: $project_slug, build_branch: $build_branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project build by version
#
# GET /projects/{accountName}/{projectSlug}/build/{buildVersion}
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-build-by-version
# Returns: record<build: record<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list<record>, messageExtended: string, messages: list<record>, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getProjectBuildByVersion
export def "get-project-build-by-version" [
  account_name: string
  project_slug: string
  build_version: string
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
    path: "/projects/{accountName}/{projectSlug}/build/{buildVersion}"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}, {name: buildVersion, var: build_version}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: none
  } {
    account_name: $account_name, project_slug: $project_slug, build_version: $build_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete project build cache
#
# DELETE /projects/{accountName}/{projectSlug}/buildcache
# Docs: https://www.appveyor.com/docs/api/projects-builds/#delete-project-build-cache
# operationId: deleteProjectBuildCache
export def "delete-project-build-cache" [
  account_name: string
  project_slug: string
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
    method: delete
    path: "/projects/{accountName}/{projectSlug}/buildcache"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project deployments
#
# GET /projects/{accountName}/{projectSlug}/deployments
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-deployments
# Returns: record<deployments: table<build: record, deploymentId: int, finished: string, started: string, status: string, environment: record>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getProjectDeployments
export def "get-project-deployments" [
  account_name: string
  project_slug: string
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
  --records-number: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time. As of 2018-09-08, the value used by the web interface is 10. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{accountName}/{projectSlug}/deployments"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    query: [{name: recordsNumber, var: records_number, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug, records_number: $records_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project history
#
# GET /projects/{accountName}/{projectSlug}/history
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-history
# Returns: record<builds: table<branch: string, buildId: int, message: string, version: string, created: string, updated: string, authorName: string, authorUsername: string, buildNumber: int, commitId: string, committed: string, committerName: string, committerUsername: string, finished: string, isTag: bool, jobs: list, messageExtended: string, messages: list, projectId: int, pullRequestId: int, pullRequestName: string, started: string, status: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>>
# operationId: getProjectHistory
export def "get-project-history" [
  account_name: string
  project_slug: string
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
  --records-number: int # Number of results to include in the response. getProjectDeployments is documented to have a maximum of 20. It currently returns 500 Internal Server Error for recordsNumber <= 5. In the past it has returned 500 Internal Server Error for many different values which did not match the value used by the ci.appveyor.com web interface at the time. As of 2018-09-08, the value used by the web interface is 10. (required)
  --start-build-id: int # Maximum `buildId` to include in the results (exclusive).
  --branch: string # Repository Branch
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{accountName}/{projectSlug}/history"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    query: [{name: recordsNumber, var: records_number, required: true}, {name: startBuildId, var: start_build_id}, {name: branch, var: branch}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: none
  } {
    account_name: $account_name, project_slug: $project_slug, records_number: $records_number, start_build_id: $start_build_id, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project settings
#
# GET /projects/{accountName}/{projectSlug}/settings
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings
# Returns: record<buildClouds: table<value: string>, defaultImageName: string, images: table<buildCloudName: string, buildWorkerImageId: int, name: string, osType: string>, project: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string>, settings: record<accountName: string, name: string, projectId: int, slug: string, created: string, updated: string, accountId: int, alwaysBuildClosedPullRequests: bool, builds: list<record>, currentBuildId: int, disablePullRequestWebhooks: bool, disablePushWebhooks: bool, enableDeploymentInPullRequests: bool, enableSecureVariablesInPullRequests: bool, enableSecureVariablesInPullRequestsFromSameRepo: bool, isGitHubApp: bool, isPrivate: bool, nuGetFeed: record<created: string, updated: string, accountId: int, id: string, isPrivateProject: bool, name: string, nuGetFeedId: int, projectId: int, publishingEnabled: bool>, repositoryBranch: string, repositoryName: string, repositoryScm: string, repositoryType: string, rollingBuilds: bool, rollingBuildsDoNotCancelRunningBuilds: bool, rollingBuildsOnlyForPullRequests: bool, saveBuildCacheInPullRequests: bool, securityDescriptor: record<accessRightDefinitions: list, roleAces: list>, skipBranchesWithoutAppveyorYml: bool, tags: string, buildPriority: int, configuration: record<afterBuildScripts: list, afterDeployScripts: list, afterTestScripts: list, artifacts: list, assemblyFileVersionFormat: string, assemblyInfoFile: string, assemblyInformationalVersionFormat: string, assemblyVersionFormat: string, beforeBuildScripts: list, beforeDeployScripts: list, beforePackageScripts: list, beforeTestScripts: list, branchesMode: string, buildCloud: list, buildMode: string, buildScripts: list, cacheEntries: list, cloneDepth: int, cloneFolder: string, cloneScripts: list, configuration: list, configureNuGetAccountSource: bool, configureNuGetProjectSource: bool, deployMode: string, deployScripts: list, deployments: list, disableNuGetPublishForOctopusPackages: bool, disableNuGetPublishOnPullRequests: bool, doNotIncrementBuildNumberOnPullRequests: bool, dotnetCsprojAssemblyVersionFormat: string, dotnetCsprojFile: string, dotnetCsprojFileVersionFormat: string, dotnetCsprojInformationalVersionFormat: string, dotnetCsprojPackageVersionFormat: string, dotnetCsprojVersionFormat: string, environmentVariables: list, environmentVariablesMatrix: list, excludeBranches: list, forceHttpsClone: bool, hostsEntries: list, hotFixScripts: list, includeBranches: list, includeNuGetReferences: bool, initScripts: list, installScripts: list, matrixAllowFailures: list, matrixExcept: list, matrixExclude: list, matrixFastFinish: bool, matrixOnly: list, maxJobs: int, msBuildInParallel: bool, msBuildProjectFileName: string, msBuildVerbosity: string, notifications: list, onBuildErrorScripts: list, onBuildFinishScripts: list, onBuildSuccessScripts: list, onlyCommitsFiles: list, operatingSystem: list, packageAspNetCoreProjects: bool, packageAzureCloudServiceProjects: bool, packageDotnetConsoleProjects: bool, packageNuGetProjects: bool, packageNuGetSymbols: bool, packageWebApplicationProjects: bool, packageWebApplicationProjectsBeanstalk: bool, packageWebApplicationProjectsOctopus: bool, packageWebApplicationProjectsXCopy: bool, patchAssemblyInfo: bool, patchDotnetCsproj: bool, platform: list, services: list, shallowClone: bool, skipBranchWithPullRequests: bool, skipCommitsFiles: list, skipNonTags: bool, skipTags: bool, stacks: list, testAssemblies: list, testCategories: list, testCategoriesMatrix: list, testCategoriesMode: string, testMode: string, testScripts: list, xamarinRegisterAndroidProduct: bool, xamarinRegisterIosProduct: bool>, customYmlName: string, ignoreAppveyorYml: bool, nextBuildNumber: int, repositoryAuthentication: string, repositoryUsername: string, scheduleCrontabExpression: string, sshPublicKey: string, statusBadgeId: string, versionFormat: string, webhookId: string, webhookUrl: string>>
# operationId: getProjectSettings
export def "get-project-settings" [
  account_name: string
  project_slug: string
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
    path: "/projects/{accountName}/{projectSlug}/settings"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update project build number
#
# PUT /projects/{accountName}/{projectSlug}/settings/build-number
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-build-number
# operationId: updateProjectBuildNumber
export def "update-project-build-number" [
  account_name: string
  project_slug: string
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
  next_build_number: int
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects/{accountName}/{projectSlug}/settings/build-number"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextBuildNumber, var: next_build_number}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug, next_build_number: $next_build_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project environment variables
#
# GET /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-environment-variables
# Returns: table<name: string, value: record<isEncrypted: bool, value: string>>
# operationId: getProjectEnvironmentVariables
export def "get-project-environment-variables" [
  account_name: string
  project_slug: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{accountName}/{projectSlug}/settings/environment-variables"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update project environment variables
#
# PUT /projects/{accountName}/{projectSlug}/settings/environment-variables
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-environment-variables
# operationId: updateProjectEnvironmentVariables
export def "update-project-environment-variables" [
  account_name: string
  project_slug: string
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
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects/{accountName}/{projectSlug}/settings/environment-variables"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get project settings in YAML
#
# GET /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#get-project-settings-in-yaml
# Returns: string
# operationId: getProjectSettingsYaml
export def "get-project-settings-yaml" [
  account_name: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/projects/{accountName}/{projectSlug}/settings/yaml"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project settings in YAML
#
# PUT /projects/{accountName}/{projectSlug}/settings/yaml
# Docs: https://www.appveyor.com/docs/api/projects-builds/#update-project-settings-in-yaml
# operationId: updateProjectSettingsYaml
export def "update-project-settings-yaml" [
  account_name: string
  project_slug: string
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
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/projects/{accountName}/{projectSlug}/settings/yaml"
    path_params: [{name: accountName, var: account_name}, {name: projectSlug, var: project_slug}]
    body: {content_type: "text/plain", kind: opaque, accepts: scalar}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_name: $account_name, project_slug: $project_slug, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get roles
#
# GET /roles
# Docs: https://www.appveyor.com/docs/api/team/#get-roles
# Returns: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>
# operationId: getRoles
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add role
#
# POST /roles
# Docs: https://www.appveyor.com/docs/api/team/#add-role
# Returns: record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>
# operationId: addRole
export def "add-role" [
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
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update role
#
# PUT /roles
# Docs: https://www.appveyor.com/docs/api/team/#update-role
# Returns: record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>
# operationId: updateRole
export def "update-role" [
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
  name: string
  role_id: int
  --groups: list # item shape: {name: "Account"|"BuildEnvironment"|"Deny"|"Environments"|"Projects"|"Roles"|"User"|"Users", permissions: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: roleId, var: role_id}, {name: groups, var: groups}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, role_id: $role_id, groups: $groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete role
#
# DELETE /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-role
# operationId: deleteRole
export def "delete-role" [
  role_id: int
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
    method: delete
    path: "/roles/{roleId}"
    path_params: [{name: roleId, var: role_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get role
#
# GET /roles/{roleId}
# Docs: https://www.appveyor.com/docs/api/team/#get-role
# Returns: record<created: string, updated: string, isSystem: bool, name: string, roleId: int, groups: table<name: string, permissions: list>>
# operationId: getRole
export def "get-role" [
  role_id: int
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
    path: "/roles/{roleId}"
    path_params: [{name: roleId, var: role_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Join Account
#
# PUT /user/join-account
# Returns: record<accounts: table<created: string, updated: string, accountId: int, allowCustomBuildEnvironment: bool, blocked: bool, featureFlags: string, gitHubPlan: bool, gitHubPlanOrg: string, isCollaborator: bool, isEnterprisePlan: bool, isOwner: bool, manualPayments: bool, name: string, permissions: list, planEnd: string, planId: string, planStart: string, planStatus: string, roleId: int, roleName: string, timeZoneId: string, unpaid: bool, unverified: bool>, setupRequired: bool, twoFactorAuthRequired: bool, user: record<created: string, updated: string, bitBucketUsername: string, email: string, fullName: string, gitHubUsername: string, gitLabUserId: string, gravatarHash: string, pageSize: int, twoFactorAuthEnabled: bool, userId: int, vsoUsername: string>>
# operationId: joinAccount
export def "join-account" [
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
  invitation_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user/join-account"
    body: {content_type: "application/json", kind: json, fields: [{name: invitationId, var: invitation_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    invitation_id: $invitation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get users
#
# GET /users
# Docs: https://www.appveyor.com/docs/api/team/#get-users
# Returns: table<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user
#
# PUT /users
# Docs: https://www.appveyor.com/docs/api/team/#update-user
# operationId: updateUser
export def "update-user" [
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
  email: string # format: email
  full_name: string
  --password: string # format: password
  --role-id: int
  --two-factor-auth-enabled: oneof<nothing, bool>
  --user-id: int
]: any -> any {
  $in | http-request {
    method: put
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fullName, var: full_name}, {name: password, var: password}, {name: roleId, var: role_id}, {name: twoFactorAuthEnabled, var: two_factor_auth_enabled}, {name: userId, var: user_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    email: $email, full_name: $full_name, password: $password, role_id: $role_id, two_factor_auth_enabled: $two_factor_auth_enabled, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user invitations
#
# GET /users/invitations
# Returns: table<accountId: int, accountName: string, created: string, email: string, roleId: int, roleName: string, userInvitationId: string>
# operationId: getUserInvitations
export def "get-user-invitations" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/invitations"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite user
#
# POST /users/invitations
# operationId: inviteUser
export def "invite-user" [
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
  email: string # format: email
  role_id: int
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/invitations"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: roleId, var: role_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    email: $email, role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel user invitation
#
# DELETE /users/invitations/{userInvitationId}
# operationId: cancelUserInvitation
export def "cancel-user-invitation" [
  user_invitation_id: string
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
    method: delete
    path: "/users/invitations/{userInvitationId}"
    path_params: [{name: userInvitationId, var: user_invitation_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_invitation_id: $user_invitation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete user
#
# DELETE /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#delete-user
# operationId: deleteUser
export def "delete-user" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user
#
# GET /users/{userId}
# Docs: https://www.appveyor.com/docs/api/team/#get-user
# Returns: record<roles: table<created: string, updated: string, isSystem: bool, name: string, roleId: int>, user: record<created: string, updated: string, accountId: int, accountName: string, email: string, fullName: string, isCollaborator: bool, isOwner: bool, pageSize: int, password: string, roleId: int, roleName: string, twoFactorAuthEnabled: bool, userId: int>>
# operationId: getUser
export def "get-user" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
