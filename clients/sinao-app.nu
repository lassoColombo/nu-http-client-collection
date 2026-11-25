# Auto-generated client for Sinao API v1.1.0
# Source: https://api.apis.guru/v2/specs/sinao.app/1.1.0/openapi.json
# Auth: --token flag or $env.SINAO_API_TOKEN

const CLIENT = {
  base_url: "https://api.sinao.app/v1"
  token_env_var: "SINAO_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://api.sinao.app/v1" "https://api.sinao.dev/v1" "https://api.sinao.test/v1"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["invoice" "none" "purchase" "quote" "relationship" "transaction"] }
def type-completer-1 [] { ["sap"] }
def type-completer-2 [] { ["bank" "cashdesk" "waiting"] }
def account-type-completer [] { ["card" "checking" "life_insurance" "loan" "pending" "savings" "securities" "share_savings_plan" "special" "unknown"] }
def format-completer [] { ["acd" "fiducial" "quadra" "universal"] }
def template-completer [] { ["command" "delivery"] }
def status-completer [] { ["draft" "final" "paid"] }
def type-completer-3 [] { ["product" "service"] }
def vat-repayment-completer [] { ["billing" "payment"] }
def status-completer-1 [] { ["completed" "paid"] }
def status-completer-2 [] { ["deleted" "goodforagreement" "refused" "transformed" "waiting"] }
def type-completer-4 [] { ["purchase" "sales" "transaction"] }
def frequency-duration-completer [] { ["day" "month" "semester" "trimester" "week" "year"] }
def discount-mode-completer [] { ["percent"] }
def period-completer [] { ["daily" "hourly" "monthly" "quarterly" "weekly" "yearly"] }
def object-completer [] { ["invoice" "payment" "purchase" "quote" "relationship" "transaction"] }
def calcul-completer [] { ["avg" "count" "sum"] }
def period-completer-1 [] { ["half-yearly" "monthly" "quarterly" "yearly"] }
def object-completer-1 [] { ["invoice" "product" "purchase" "quote"] }
def method-completer [] { ["automatic_debit" "cash" "check" "creditcard" "creditnote" "transfer"] }
def type-completer-5 [] { ["contact" "invoice" "quote"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    app-list: "table<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>"
    app-create: "record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>"
    app-policies-registration-delete: "record<code: int, message: string, type: string>"
    app-policies-registration-get: "record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>"
    app-policies-registration-register: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>"
    app-get: "record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>"
    app-policies-list: "table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>"
    app-policies-invitations-list: "table<app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: record, policies: list, subscription: record, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list, visible: int>, recipient_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>"
    app-policies-invitations-create: "record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>"
    app-policies-invitations-delete: "record<code: int, message: string, type: string>"
    app-policies-profiles-list: "table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>"
    app-policies-delete: "record<code: int, message: string, type: string>"
    app-policies-get: "record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>"
    app-policies-update: "record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>"
    app-accounting-categories-list: "table<description: string, id: int, name: string, type: string>"
    app-accounting-categories-create: "record<description: string, id: int, name: string, type: string>"
    app-accounting-categories-get: "record<description: string, id: int, name: string, type: string>"
    app-accounting-categories-update: "record<description: string, id: int, name: string, type: string>"
    app-accounting-entries-list: "table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-accounting-accounts-list: "table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-accounting-accounts-create: "record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-accounting-accounts-batch: "record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-accounting-accounts-get: "record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-accounting-accounts-update: "record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>"
    app-apikeys-list: "record"
    app-apikeys-create: "record<code: int, message: string, type: string>"
    app-apipartners-list: "record"
    app-attachments-list: "table<attachable_id: string, attachable_type: string, file_url: string, id: int, name: string>"
    app-attachments-download: "binary"
    app-sap-attestations-download: "binary"
    app-attachments-redirect-to-public-url: "binary"
    app-documents-sales-bankdetails-list: "table<bic: string, iban: string, id: int, name: string>"
    app-documents-sales-bankdetails-create: "record<bic: string, iban: string, id: int, name: string>"
    app-documents-sales-bankdetails-get: "record<bic: string, iban: string, id: int, name: string>"
    app-documents-sales-bankdetails-update: "record<bic: string, iban: string, id: int, name: string>"
    app-cashflow-banks-delete: "record"
    app-cashflow-banks-list: "record"
    app-cashflow-banks-connect: "record<url: string>"
    app-cashflow-banks-synchronize: "record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-cashflow-banks-url-edit: "record<url: string>"
    app-cashflow-banks-url-sync: "record<url: string>"
    app-cashflow-banks-url-validate: "record<url: string>"
    app-cashflow-banks-select-accounts: "record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-cashflow-cashflowsources-list: "table<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-cashflow-cashflowsources-create: "record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-cashflow-cashflowsources-get: "record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-cashflow-cashflowsources-update: "record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>"
    app-contacts-establishments-delete: "record<code: int, message: string, type: string>"
    app-contacts-establishments-get: "record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>>"
    app-contacts-establishments-update: "record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>>"
    app-accounting-export-list: "table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>"
    app-accounting-export-create: "record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>"
    app-accounting-export-acd-compta-get-uuid: "record<uuid: string>"
    app-accounting-export-acd-compta-set-uuid: "record<uuid: string>"
    app-accounting-export-download: "binary"
    app-accounting-export-list-by-months: "table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>"
    app-accounting-export-get: "record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>"
    app-documents-sales-invoices-list: "table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-invoices-create: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-invoices-batch-delete: "record<code: int, message: string, type: string>"
    app-documents-sales-invoices-batch: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-invoices-download: "binary"
    app-documents-sales-invoices-fresh: "record"
    app-documents-sales-invoices-statistics: "record"
    app-documents-sales-invoices-delete: "record<code: int, message: string, type: string>"
    app-documents-sales-invoices-get: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-invoices-update: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-invoices-pdf: "binary"
    app-documents-sales-invoices-preview: "binary"
    app-organization-get: "table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: any, policies: list, subscription: record, url: string>>"
    app-organization-update: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: any, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>>"
    app-contacts-organizations-list: "table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-contacts-organizations-create: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-contacts-organizations-batch: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-contacts-organizations-delete: "record<code: int, message: string, type: string>"
    app-contacts-organizations-get: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-contacts-organizations-update: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-contacts-organizations-restore: "record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>"
    app-payments-payments-list: "table<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record, cashflow_source: record, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list, method: int, received_at: string, updated_at: string>>"
    app-payments-payments-delete: "record<code: int, message: string, type: string>"
    app-payments-payments-get: "record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>>"
    app-contacts-persons-list: "table<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-contacts-persons-create: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-contacts-persons-batch: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-contacts-persons-delete: "record<code: int, message: string, type: string>"
    app-contacts-persons-get: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-contacts-persons-update: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-contacts-persons-restore: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>"
    app-catalog-categories-list: "table<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>>"
    app-catalog-categories-create: "record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>"
    app-catalog-categories-delete: "record<code: int, message: string, type: string>"
    app-catalog-categories-get: "record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>"
    app-catalog-categories-update: "record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>"
    app-catalog-products-list: "table<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>"
    app-catalog-products-create: "record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>"
    app-catalog-products-batch: "record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>"
    app-catalog-products-delete: "record<code: int, message: string, type: string>"
    app-catalog-products-get: "record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>"
    app-catalog-products-update: "record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>"
    app-catalog-stocks-list: "table<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>, product_stocks_movements: list<record>, purchase: record<account: record, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record, supplier_name: string, tags: list, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: list<record>, use_duration: int>"
    app-catalog-stocks-create: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-catalog-stocks-delete: "record<code: int, message: string, type: string>"
    app-catalog-stocks-get: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-catalog-stocks-update: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-catalog-stocks-destruct: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-catalog-stocks-rental-back: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-catalog-stocks-rental-exit: "record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>"
    app-documents-purchases-purchases-list: "table<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>"
    app-documents-purchases-purchases-create: "record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>"
    app-documents-purchases-purchases-batch-delete: "record<code: int, message: string, type: string>"
    app-documents-purchases-purchases-batch: "record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>"
    app-documents-purchases-purchases-download: "binary"
    app-documents-purchases-purchases-statistics: "record"
    app-documents-purchases-purchases-delete: "record<code: int, message: string, type: string>"
    app-documents-purchases-purchases-get: "record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>"
    app-documents-purchases-purchases-update: "record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>"
    app-documents-purchases-purchases-original: "binary"
    app-documents-purchases-purchases-preview: "binary"
    app-documents-purchases-purchases-thumbnail: "binary"
    app-documents-sales-quotes-list: "table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-create: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-batch-delete: "record<code: int, message: string, type: string>"
    app-documents-sales-quotes-batch: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-download: "binary"
    app-documents-sales-quotes-fresh: "record"
    app-documents-sales-quotes-invoices: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-quotes-statistics: "record"
    app-documents-sales-quotes-delete: "record<code: int, message: string, type: string>"
    app-documents-sales-quotes-get: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-update: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-downpayment: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-quotes-duplicate: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-quotes-invoice: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-quotes-pdf: "binary"
    app-documents-sales-quotes-preview: "binary"
    app-documents-sales-quotes-situation-invoice: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-documents-sales-quotes-yousign-preview: "binary"
    app-payments-reconciliation-unreconcile: "record<code: int, message: string, type: string>"
    app-payments-reconciliation-reconcile: "record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>>"
    app-payments-reconciliation-batch: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>"
    app-documents-sales-recurringinvoices-list: "table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>"
    app-documents-sales-recurringinvoices-create: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>"
    app-documents-sales-recurringinvoices-batch-delete: "record<code: int, message: string, type: string>"
    app-documents-sales-recurringinvoices-batch: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>"
    app-documents-sales-recurringinvoices-get-periods: "list<any>"
    app-documents-sales-recurringinvoices-get: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>"
    app-documents-sales-recurringinvoices-update: "record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>"
    app-documents-sales-recurringinvoices-plan: "table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>"
    app-contacts-relationships-list: "table<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>"
    app-contacts-relationships-get: "record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>"
    app-contacts-relationships-update: "record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>"
    app-rules-list: "table<conditions: list<list>, id: int, on_event: string, parameter: string, priority: int, value: string>"
    app-rules-create: "record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>"
    app-rules-execute-on: "record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>"
    app-rules-get: "record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>"
    app-rules-update: "record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>"
    app-documents-sales-models-list: "table<id: int, json: list<record>, name: string, title: string>"
    app-documents-sales-models-create: "record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>"
    app-documents-sales-models-get: "record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>"
    app-documents-sales-models-update: "record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>"
    app-payments-sepamandates-list: "table<author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>"
    app-payments-sepamandates-create: "record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>"
    app-payments-sepacredittransfer-preview: "record"
    app-payments-sepadirectdebit-preview: "record"
    app-payments-sepamandates-get: "record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>"
    app-payments-sepamandates-update: "record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>"
    app-settings-get: "record"
    app-settings-update: "record<code: int, message: string, type: string>"
    app-statistics-charts-get: "list<record>"
    app-statistics-timetable-purchases: "table<balance: int, count: int, data: list<record>, interval: list<string>>"
    app-statistics-timetable-sales: "table<balance: int, count: int, data: list<record>, interval: list<string>>"
    app-statistics-vat-get: "record"
    app-subscription-get: "record<extras: list<string>, plans: list<string>>"
    app-subscription-list: "record<extras: list<string>, plans: list<string>>"
    app-statistics-tags-get: "list<record>"
    app-cashflow-transactions-list: "table<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>"
    app-cashflow-transactions-create: "record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>"
    app-cashflow-transactions-batch: "record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>"
    app-cashflow-transactions-get: "record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>"
    app-cashflow-transactions-update: "record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>"
    app-payments-urssaftiers-get-status: "record"
    app-payments-urssaftiers-preview: "record"
    account-get: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>"
    account-update: "record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>"
    auth-refresh: "record<access_token: string, expires_in: int, token_type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["app-list" "app-create" "app-policies-registration-delete" "app-policies-registration-get" "app-policies-registration-register" "app-get" "app-policies-list" "app-policies-invitations-list" "app-policies-invitations-create" "app-policies-invitations-delete" "app-policies-profiles-list" "app-policies-delete" "app-policies-get" "app-policies-update" "app-accounting-categories-list" "app-accounting-categories-create" "app-accounting-categories-delete" "app-accounting-categories-get" "app-accounting-categories-update" "app-accounting-entries-list" "app-accounting-accounts-list" "app-accounting-accounts-create" "app-accounting-accounts-batch" "app-accounting-accounts-delete" "app-accounting-accounts-get" "app-accounting-accounts-update" "app-apikeys-list" "app-apikeys-create" "app-apikeys-delete" "app-apipartners-list" "app-attachments-list" "app-attachments-create" "app-sap-attestations-generate-sap-attestations" "app-attachments-download" "app-sap-attestations-download" "app-attachments-delete" "app-attachments-get" "app-attachments-redirect-to-public-url" "app-documents-sales-bankdetails-list" "app-documents-sales-bankdetails-create" "app-documents-sales-bankdetails-delete" "app-documents-sales-bankdetails-get" "app-documents-sales-bankdetails-update" "app-cashflow-banks-delete" "app-cashflow-banks-list" "app-cashflow-banks-connect" "app-cashflow-banks-synchronize" "app-cashflow-banks-url-edit" "app-cashflow-banks-url-sync" "app-cashflow-banks-url-validate" "app-cashflow-banks-select-accounts" "app-cashflow-cashflowsources-list" "app-cashflow-cashflowsources-create" "app-cashflow-cashflowsources-delete" "app-cashflow-cashflowsources-get" "app-cashflow-cashflowsources-update" "app-contacts-transform-merge" "app-contacts-email-batch" "app-contacts-email-send" "app-contacts-establishments-delete" "app-contacts-establishments-get" "app-contacts-establishments-update" "app-accounting-export-list" "app-accounting-export-create" "app-accounting-export-acd-compta-get-uuid" "app-accounting-export-acd-compta-set-uuid" "app-accounting-export-download" "app-accounting-export-list-by-months" "app-accounting-export-delete" "app-accounting-export-get" "app-documents-sales-invoices-list" "app-documents-sales-invoices-create" "app-documents-sales-invoices-batch-delete" "app-documents-sales-invoices-batch" "app-documents-sales-invoices-download" "app-documents-sales-invoices-fresh" "app-documents-sales-invoices-nextnumber" "app-documents-sales-invoices-statistics" "app-documents-sales-invoices-delete" "app-documents-sales-invoices-get" "app-documents-sales-invoices-update" "app-documents-sales-invoices-detach" "app-documents-sales-invoices-attach" "app-documents-sales-invoices-avoid" "app-documents-sales-invoices-duplicate" "app-documents-sales-invoices-finalize" "app-documents-sales-invoices-pdf" "app-documents-sales-invoices-preview" "app-documents-sales-invoices-untag" "app-documents-sales-invoices-tag" "app-documents-sales-invoices-updatestatus" "app-cashflow-logsautoreconciliations-clear" "app-cashflow-logsautoreconciliations-list" "app-cashflow-logsautoreconciliations-start" "app-organization-get" "app-organization-update" "app-contacts-organizations-list" "app-contacts-organizations-create" "app-contacts-organizations-batch" "app-contacts-organizations-delete" "app-contacts-organizations-get" "app-contacts-organizations-update" "app-contacts-organizations-restore" "app-payments-payments-list" "app-payments-payments-recipe-book" "app-payments-payments-delete" "app-payments-payments-get" "app-contacts-persons-list" "app-contacts-persons-create" "app-contacts-persons-batch" "app-contacts-persons-delete" "app-contacts-persons-get" "app-contacts-persons-update" "app-contacts-persons-restore" "app-ping" "app-catalog-categories-list" "app-catalog-categories-create" "app-catalog-categories-delete" "app-catalog-categories-get" "app-catalog-categories-update" "app-catalog-products-list" "app-catalog-products-create" "app-catalog-products-batch" "app-catalog-products-delete" "app-catalog-products-get" "app-catalog-products-update" "app-catalog-products-detach" "app-catalog-products-attach" "app-catalog-stocks-list" "app-catalog-stocks-create" "app-catalog-stocks-delete" "app-catalog-stocks-get" "app-catalog-stocks-update" "app-catalog-stocks-destruct" "app-catalog-stocks-rental-back" "app-catalog-stocks-rental-exit" "app-documents-purchases-purchases-list" "app-documents-purchases-purchases-create" "app-documents-purchases-purchases-batch-delete" "app-documents-purchases-purchases-batch" "app-documents-purchases-purchases-download" "app-documents-purchases-purchases-statistics" "app-documents-purchases-purchases-delete" "app-documents-purchases-purchases-get" "app-documents-purchases-purchases-update" "app-documents-purchases-purchases-detach" "app-documents-purchases-purchases-attach" "app-documents-purchases-purchases-original" "app-documents-purchases-purchases-preview" "app-documents-purchases-purchases-untag" "app-documents-purchases-purchases-tag" "app-documents-purchases-purchases-thumbnail" "app-documents-purchases-purchases-updatestatus" "app-documents-sales-quotes-list" "app-documents-sales-quotes-create" "app-documents-sales-quotes-batch-delete" "app-documents-sales-quotes-batch" "app-documents-sales-quotes-download" "app-documents-sales-quotes-fresh" "app-documents-sales-quotes-invoices" "app-documents-sales-quotes-nextnumber" "app-documents-sales-quotes-statistics" "app-documents-sales-quotes-delete" "app-documents-sales-quotes-get" "app-documents-sales-quotes-update" "app-documents-sales-quotes-detach" "app-documents-sales-quotes-attach" "app-documents-sales-quotes-downpayment" "app-documents-sales-quotes-duplicate" "app-documents-sales-quotes-finalize" "app-documents-sales-quotes-invoice" "app-documents-sales-quotes-pdf" "app-documents-sales-quotes-preview" "app-documents-sales-quotes-situation-invoice" "app-documents-sales-quotes-untag" "app-documents-sales-quotes-tag" "app-documents-sales-quotes-updatestatus" "app-documents-sales-quotes-yousign-preview" "app-payments-reconciliation-unreconcile" "app-payments-reconciliation-reconcile" "app-payments-reconciliation-batch" "app-documents-sales-recurringinvoices-list" "app-documents-sales-recurringinvoices-create" "app-documents-sales-recurringinvoices-batch-delete" "app-documents-sales-recurringinvoices-batch" "app-documents-sales-recurringinvoices-get-periods" "app-documents-sales-recurringinvoices-delete" "app-documents-sales-recurringinvoices-get" "app-documents-sales-recurringinvoices-update" "app-documents-sales-recurringinvoices-plan" "app-contacts-relationships-list" "app-contacts-relationships-get" "app-contacts-relationships-update" "app-contacts-relationships-detach" "app-contacts-relationships-attach" "app-reset" "app-rules-list" "app-rules-create" "app-rules-execute-on" "app-rules-delete" "app-rules-get" "app-rules-update" "app-documents-sales-models-list" "app-documents-sales-models-create" "app-documents-sales-models-delete" "app-documents-sales-models-get" "app-documents-sales-models-update" "app-payments-sepamandates-list" "app-payments-sepamandates-create" "app-payments-sepacredittransfer-preview" "app-payments-sepacredittransfer-download" "app-payments-sepadirectdebit-preview" "app-payments-sepadirectdebit-download" "app-payments-sepamandates-delete" "app-payments-sepamandates-get" "app-payments-sepamandates-update" "app-services-stripe-webhook-ping" "app-services-stripe-webhook-handle" "app-services-yousign-webhook-handle" "app-settings-get" "app-settings-update" "app-documents-sales-signature-create" "app-statistics-charts-get" "app-statistics-timetable-purchases" "app-statistics-timetable-sales" "app-statistics-vat-get" "app-subscription-anchordate" "app-subscription-checkout-add-source" "app-subscription-coupon" "app-subscription-extend-trial" "app-subscription-extra-enable" "app-subscription-pay-all" "app-subscription-end" "app-subscription-get" "app-subscription-list" "app-subscription-upcoming" "app-subscription-pay" "app-subscription-checkout" "app-subscription-remove-source" "app-subscription-add-source" "app-subscription-set-default" "app-statistics-tags-get" "app-settings-templates-list" "app-settings-templates-create" "app-settings-templates-batch" "app-settings-templates-default-template" "app-settings-templates-get" "app-settings-templates-update" "app-cashflow-transactions-list" "app-cashflow-transactions-create" "app-cashflow-transactions-batch" "app-cashflow-transactions-delete" "app-cashflow-transactions-get" "app-cashflow-transactions-update" "app-cashflow-transactions-detach" "app-cashflow-transactions-attach" "app-payments-urssaftiers-auth" "app-payments-urssaftiers-get-status" "app-payments-urssaftiers-send-payments" "app-payments-urssaftiers-preview" "app-payments-urssaftiers-register-customer" "auth-changepassword" "auth-login" "auth-logout" "account-get" "account-update" "auth-ping" "auth-refresh" "account-create" "auth-sendpassword" "admin-purchase-collector-push" "services-vies-get" "commands"] | sort) } | get name | first)
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

# List apps
#
# GET /apps
# Returns: table<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>
# operationId: app.list
export def "app-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps"
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an app
#
# POST /apps
# Returns: record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>
# operationId: app.create
export def "app-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-name: string # Organization name. Minimum 3 characters with 1 alpha (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps"
    query: [{name: organization_name, var: organization_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    organization_name: $organization_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an invitation from token
#
# DELETE /apps/access/invite/{accessToken}
# Returns: record<code: int, message: string, type: string>
# operationId: app.policies.registration.delete
export def "app-policies-registration-delete" [
  access_token: string
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
    path: "/apps/access/invite/{accessToken}"
    path_params: [{name: accessToken, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invitation informations
#
# GET /apps/access/invite/{accessToken}
# Returns: record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>
# operationId: app.policies.registration.get
export def "app-policies-registration-get" [
  access_token: string
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
    path: "/apps/access/invite/{accessToken}"
    path_params: [{name: accessToken, var: access_token}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an User by invitation
#
# POST /apps/access/invite/{accessToken}/register
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>
# operationId: app.policies.registration.register
export def "app-policies-registration-register" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Password for account (required)
  --firstname: string # First name of user before account creation / account link
  --lastname: string # Last name of user before account creation / account link
  --cgu: oneof<nothing, bool> # User has valided CGU ? (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/access/invite/{accessToken}/register"
    path_params: [{name: accessToken, var: access_token}]
    query: [{name: password, var: password, required: true}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: cgu, var: cgu, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    access_token: $access_token, password: $password, firstname: $firstname, lastname: $lastname, cgu: $cgu
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an app
#
# GET /apps/{appId}
# Returns: record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>
# operationId: app.get
export def "app-get" [
  app_id: int
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
    path: "/apps/{appId}"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get policies for an app
#
# GET /apps/{appId}/access
# Returns: table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>
# operationId: app.policies.list
export def "app-policies-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/access"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List invitations
#
# GET /apps/{appId}/access/invite
# Returns: table<app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: record, policies: list, subscription: record, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list, visible: int>, recipient_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>
# operationId: app.policies.invitations.list
export def "app-policies-invitations-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/access/invite"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite an user
#
# POST /apps/{appId}/access/invite
# Returns: record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string>
# operationId: app.policies.invitations.create
export def "app-policies-invitations-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for invitation. Will be used to account creation or account matching with an existing user (required)
  --policy-profile-id: int # Profile for policies set (required)
  --firstname: string # First name of user before account creation / account link
  --lastname: string # Last name of user before account creation / account link
  --civility: string # Last name of user before account creation / account link
  --password: string # Password for new user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/access/invite"
    path_params: [{name: appId, var: app_id}]
    query: [{name: email, var: email, required: true}, {name: policy_profile_id, var: policy_profile_id, required: true}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: civility, var: civility}, {name: password, var: password}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, email: $email, policy_profile_id: $policy_profile_id, firstname: $firstname, lastname: $lastname, civility: $civility, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an invitation
#
# DELETE /apps/{appId}/access/invite/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.policies.invitations.delete
export def "app-policies-invitations-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/access/invite/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profiles
#
# GET /apps/{appId}/access/profiles
# Returns: table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>
# operationId: app.policies.profiles.list
export def "app-policies-profiles-list" [
  app_id: int
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
    path: "/apps/{appId}/access/profiles"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete police for an user
#
# DELETE /apps/{appId}/access/{userId}
# Returns: record<code: int, message: string, type: string>
# operationId: app.policies.delete
export def "app-policies-delete" [
  app_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/access/{userId}"
    path_params: [{name: appId, var: app_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get police for an user
#
# GET /apps/{appId}/access/{userId}
# Returns: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>
# operationId: app.policies.get
export def "app-policies-get" [
  app_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/access/{userId}"
    path_params: [{name: appId, var: app_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update police for an user
#
# POST /apps/{appId}/access/{userId}
# Returns: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>
# operationId: app.policies.update
export def "app-policies-update" [
  app_id: int
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
  --policy-profile-id: int # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/access/{userId}"
    path_params: [{name: appId, var: app_id}, {name: userId, var: user_id}]
    query: [{name: policy_profile_id, var: policy_profile_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, user_id: $user_id, policy_profile_id: $policy_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List categories
#
# GET /apps/{appId}/accountcategories/
# Returns: table<description: string, id: int, name: string, type: string>
# operationId: app.accounting.categories.list
export def "app-accounting-categories-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/accountcategories/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a category
#
# POST /apps/{appId}/accountcategories/
# Returns: record<description: string, id: int, name: string, type: string>
# operationId: app.accounting.categories.create
export def "app-accounting-categories-create" [
  app_id: int
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
  --description: string
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/accountcategories/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name}, {name: description, var: description}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, description: $description, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a category
#
# DELETE /apps/{appId}/accountcategories/{id}
# operationId: app.accounting.categories.delete
export def "app-accounting-categories-delete" [
  app_id: int
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
    path: "/apps/{appId}/accountcategories/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a category
#
# GET /apps/{appId}/accountcategories/{id}
# Returns: record<description: string, id: int, name: string, type: string>
# operationId: app.accounting.categories.get
export def "app-accounting-categories-get" [
  app_id: int
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
    path: "/apps/{appId}/accountcategories/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a category
#
# POST /apps/{appId}/accountcategories/{id}
# Returns: record<description: string, id: int, name: string, type: string>
# operationId: app.accounting.categories.update
export def "app-accounting-categories-update" [
  app_id: int
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
  --name: string
  --description: string
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/accountcategories/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: description, var: description}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, description: $description, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounting entries
#
# GET /apps/{appId}/accounting_entries/
# Returns: table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.entries.list
export def "app-accounting-entries-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/accounting_entries/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Account
#
# GET /apps/{appId}/accounts/
# Returns: table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.accounts.list
export def "app-accounting-accounts-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/accounts/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Account
#
# POST /apps/{appId}/accounts/
# Returns: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.accounts.create
export def "app-accounting-accounts-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --journalcode: string
  --name: string
  --description: string
  --keywords: string
  --accounting-number: string
  --is-cashflow: oneof<nothing, bool>
  --is-sales: oneof<nothing, bool>
  --is-purchase: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/accounts/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: journalcode, var: journalcode}, {name: name, var: name}, {name: description, var: description}, {name: keywords, var: keywords}, {name: accounting_number, var: accounting_number}, {name: is_cashflow, var: is_cashflow}, {name: is_sales, var: is_sales}, {name: is_purchase, var: is_purchase}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, journalcode: $journalcode, name: $name, description: $description, keywords: $keywords, accounting_number: $accounting_number, is_cashflow: $is_cashflow, is_sales: $is_sales, is_purchase: $is_purchase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create many accounts
#
# POST /apps/{appId}/accounts/batch
# Returns: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.accounts.batch
export def "app-accounting-accounts-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of accounts. Without ID for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/accounts/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Account
#
# DELETE /apps/{appId}/accounts/{id}
# operationId: app.accounting.accounts.delete
export def "app-accounting-accounts-delete" [
  app_id: int
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
    path: "/apps/{appId}/accounts/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Account
#
# GET /apps/{appId}/accounts/{id}
# Returns: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.accounts.get
export def "app-accounting-accounts-get" [
  app_id: int
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
    path: "/apps/{appId}/accounts/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Account
#
# POST /apps/{appId}/accounts/{id}
# Returns: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>
# operationId: app.accounting.accounts.update
export def "app-accounting-accounts-update" [
  app_id: int
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
  --journalcode: string
  --name: string
  --description: string
  --keywords: string
  --accounting-number: string
  --is-cashflow: oneof<nothing, bool>
  --is-sales: oneof<nothing, bool>
  --is-purchase: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/accounts/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: journalcode, var: journalcode}, {name: name, var: name}, {name: description, var: description}, {name: keywords, var: keywords}, {name: accounting_number, var: accounting_number}, {name: is_cashflow, var: is_cashflow}, {name: is_sales, var: is_sales}, {name: is_purchase, var: is_purchase}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, journalcode: $journalcode, name: $name, description: $description, keywords: $keywords, accounting_number: $accounting_number, is_cashflow: $is_cashflow, is_sales: $is_sales, is_purchase: $is_purchase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all api keys
#
# GET /apps/{appId}/apikeys
# Returns: record
# operationId: app.apikeys.list
export def "app-apikeys-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/apikeys"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new API key
#
# POST /apps/{appId}/apikeys
# Returns: record<code: int, message: string, type: string>
# operationId: app.apikeys.create
export def "app-apikeys-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Key name (required)
  --api-partner-id: int # Partner ID for official connexion (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/apikeys"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name, required: true}, {name: api_partner_id, var: api_partner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, name: $name, api_partner_id: $api_partner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an api key
#
# DELETE /apps/{appId}/apikeys/{id}
# operationId: app.apikeys.delete
export def "app-apikeys-delete" [
  app_id: int
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
    path: "/apps/{appId}/apikeys/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all api parners
#
# GET /apps/{appId}/apipartners
# Returns: record
# operationId: app.apipartners.list
export def "app-apipartners-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/apipartners"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments
#
# GET /apps/{appId}/attachments
# Returns: table<attachable_id: string, attachable_type: string, file_url: string, id: int, name: string>
# operationId: app.attachments.list
export def "app-attachments-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/attachments"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file on an object
#
# POST /apps/{appId}/attachments
# operationId: app.attachments.create
export def "app-attachments-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Object to attach file (required)
  --attachable-id: int # Object id
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/attachments"
    path_params: [{name: appId, var: app_id}]
    query: [{name: type, var: type, required: true}, {name: attachable_id, var: attachable_id}, {name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, type: $type, attachable_id: $attachable_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recreate S.A.P attestations
#
# PUT /apps/{appId}/attachments
# operationId: app.sapAttestations.generateSapAttestations
export def "app-sap-attestations-generate-sap-attestations" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/attachments"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a list of attachments in pdf into a .zip file
#
# GET /apps/{appId}/attachments/download
# Returns: binary
# operationId: app.attachments.download
export def "app-attachments-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Array of attachments id (required)
  --type: string@type-completer-1 # Type of attachment (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/attachments/download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, required: true}, {name: type, var: type, required: true, default: sap}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a list of SAP attestations in pdf into a .zip file
#
# GET /apps/{appId}/attachments/sap-download
# Returns: binary
# operationId: app.sapAttestations.download
export def "app-sap-attestations-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Array of attachments id (required)
  --type: string@type-completer-1 # Type of attachment (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/attachments/sap-download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, required: true}, {name: type, var: type, required: true, default: sap}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file from id
#
# DELETE /apps/{appId}/attachments/{id}
# operationId: app.attachments.delete
export def "app-attachments-delete" [
  app_id: int
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
    path: "/apps/{appId}/attachments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment by id
#
# GET /apps/{appId}/attachments/{id}
# operationId: app.attachments.get
export def "app-attachments-get" [
  app_id: int
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
    method: get
    path: "/apps/{appId}/attachments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the attachment as pdf
#
# GET /apps/{appId}/attachments/{id}/pdf
# Returns: binary
# operationId: app.attachments.RedirectToPublicUrl
export def "app-attachments-redirect-to-public-url" [
  app_id: int
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
  --random: int # random number to force fresh pdf (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/attachments/{id}/pdf"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: random, var: random, required: true}]
    accept: ["application/pdf"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, random: $random
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List BankDetails
#
# GET /apps/{appId}/bankdetails
# Returns: table<bic: string, iban: string, id: int, name: string>
# operationId: app.documents.sales.bankdetails.list
export def "app-documents-sales-bankdetails-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/bankdetails"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a BankDetails
#
# POST /apps/{appId}/bankdetails
# Returns: record<bic: string, iban: string, id: int, name: string>
# operationId: app.documents.sales.bankdetails.create
export def "app-documents-sales-bankdetails-create" [
  app_id: int
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
  --iban: string
  --bic: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/bankdetails"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name}, {name: iban, var: iban}, {name: bic, var: bic}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, iban: $iban, bic: $bic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a BankDetails
#
# DELETE /apps/{appId}/bankdetails/{id}
# operationId: app.documents.sales.bankdetails.delete
export def "app-documents-sales-bankdetails-delete" [
  app_id: int
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
    path: "/apps/{appId}/bankdetails/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a BankDetails
#
# GET /apps/{appId}/bankdetails/{id}
# Returns: record<bic: string, iban: string, id: int, name: string>
# operationId: app.documents.sales.bankdetails.get
export def "app-documents-sales-bankdetails-get" [
  app_id: int
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
    path: "/apps/{appId}/bankdetails/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a BankDetails
#
# POST /apps/{appId}/bankdetails/{id}
# Returns: record<bic: string, iban: string, id: int, name: string>
# operationId: app.documents.sales.bankdetails.update
export def "app-documents-sales-bankdetails-update" [
  app_id: int
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
  --name: string
  --iban: string
  --bic: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/bankdetails/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: iban, var: iban}, {name: bic, var: bic}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, iban: $iban, bic: $bic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Bankin synchronization
#
# DELETE /apps/{appId}/banks/
# Returns: record
# operationId: app.cashflow.banks.delete
export def "app-cashflow-banks-delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-id: int # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/banks/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: item_id, var: item_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List banks connected to bankin
#
# GET /apps/{appId}/banks/
# Returns: record
# operationId: app.cashflow.banks.list
export def "app-cashflow-banks-list" [
  app_id: int
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
    path: "/apps/{appId}/banks/"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the link to the funnel to connect a bank with Sinao
#
# GET /apps/{appId}/banks/connect
# Returns: record<url: string>
# operationId: app.cashflow.banks.connect
export def "app-cashflow-banks-connect" [
  app_id: int
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
    path: "/apps/{appId}/banks/connect"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers synchronization at Bankin then synchronizes transactions with Sinao
#
# POST /apps/{appId}/banks/synchronize
# Returns: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.banks.synchronize
export def "app-cashflow-banks-synchronize" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Optional item id to refresh. If set, triggers a refresh at Bankin before synchronizing transactions
  --is-incremential: oneof<nothing, bool> # The value 'false' triggers a non-incremental syncronization of the maximum possible duration. The value 'true' updates the transactions updated by Bankin since a certain date
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/banks/synchronize"
    path_params: [{name: appId, var: app_id}]
    query: [{name: id, var: id}, {name: is_incremential, var: is_incremential}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, is_incremential: $is_incremential
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the link to the funnel to edit password
#
# GET /apps/{appId}/banks/{id}/funnel/edit
# Returns: record<url: string>
# operationId: app.cashflow.banks.url_edit
export def "app-cashflow-banks-url-edit" [
  app_id: int
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
    path: "/apps/{appId}/banks/{id}/funnel/edit"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the link to the funnel to start manually a synchronization (SCA)
#
# GET /apps/{appId}/banks/{id}/funnel/sync
# Returns: record<url: string>
# operationId: app.cashflow.banks.url_sync
export def "app-cashflow-banks-url-sync" [
  app_id: int
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
    path: "/apps/{appId}/banks/{id}/funnel/sync"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the link to the funnel to validate a pro item (SCA)
#
# GET /apps/{appId}/banks/{id}/funnel/validate
# Returns: record<url: string>
# operationId: app.cashflow.banks.url_validate
export def "app-cashflow-banks-url-validate" [
  app_id: int
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
    path: "/apps/{appId}/banks/{id}/funnel/validate"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Select accounts to synchronize
#
# POST /apps/{appId}/banks/{id}/select_accounts
# Returns: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.banks.select_accounts
export def "app-cashflow-banks-select-accounts" [
  app_id: int
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
  --bank-account-ids: list<int> # List of enables accounts (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/banks/{id}/select_accounts"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: bank_account_ids, var: bank_account_ids, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, bank_account_ids: $bank_account_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List CashflowSource
#
# GET /apps/{appId}/cashflowsources/
# Returns: table<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.cashflowsources.list
export def "app-cashflow-cashflowsources-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/cashflowsources/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a CashflowSource
#
# POST /apps/{appId}/cashflowsources/
# Returns: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.cashflowsources.create
export def "app-cashflow-cashflowsources-create" [
  app_id: int
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
  --identifiant: string
  --type: string@type-completer-2
  --balance-amount: int
  --account-type: string@account-type-completer
  --parent-cashflow-source-id: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/cashflowsources/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name}, {name: identifiant, var: identifiant}, {name: type, var: type}, {name: balance_amount, var: balance_amount}, {name: account_type, var: account_type}, {name: parent_cashflow_source_id, var: parent_cashflow_source_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, identifiant: $identifiant, type: $type, balance_amount: $balance_amount, account_type: $account_type, parent_cashflow_source_id: $parent_cashflow_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a CashflowSource
#
# DELETE /apps/{appId}/cashflowsources/{id}
# operationId: app.cashflow.cashflowsources.delete
export def "app-cashflow-cashflowsources-delete" [
  app_id: int
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
    path: "/apps/{appId}/cashflowsources/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a CashflowSource
#
# GET /apps/{appId}/cashflowsources/{id}
# Returns: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.cashflowsources.get
export def "app-cashflow-cashflowsources-get" [
  app_id: int
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
    path: "/apps/{appId}/cashflowsources/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a CashflowSource
#
# POST /apps/{appId}/cashflowsources/{id}
# Returns: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>
# operationId: app.cashflow.cashflowsources.update
export def "app-cashflow-cashflowsources-update" [
  app_id: int
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
  --name: string
  --identifiant: string
  --type: string@type-completer-2
  --balance-amount: int
  --account-type: string@account-type-completer
  --parent-cashflow-source-id: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/cashflowsources/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: identifiant, var: identifiant}, {name: type, var: type}, {name: balance_amount, var: balance_amount}, {name: account_type, var: account_type}, {name: parent_cashflow_source_id, var: parent_cashflow_source_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, identifiant: $identifiant, type: $type, balance_amount: $balance_amount, account_type: $account_type, parent_cashflow_source_id: $parent_cashflow_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge many contacts
#
# POST /apps/{appId}/contacts/merge
# operationId: app.contacts.transform.merge
export def "app-contacts-transform-merge" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contacts: list # required, nullable
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/contacts/merge"
    path_params: [{name: appId, var: app_id}]
    query: [{name: contacts, var: contacts, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send emails
#
# POST /apps/{appId}/email/batch
# operationId: app.contacts.email.batch
export def "app-contacts-email-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # format: email
  --messages: list
  --need-copy-bcc: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/email/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: from, var: from}, {name: messages, var: messages, style: multi}, {name: need_copy_bcc, var: need_copy_bcc}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, from: $from, messages: $messages, need_copy_bcc: $need_copy_bcc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an email
#
# POST /apps/{appId}/email/document
# operationId: app.contacts.email.send
export def "app-contacts-email-send" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # format: email
  --recipients: list<string> # required
  --recipients-cc: list<string>
  --recipients-bcc: list<string>
  --title: string
  --qp-body: string # (spec name: body)
  --documents: list # required
  --need-copy-bcc: oneof<nothing, bool> # default: false
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/email/document"
    path_params: [{name: appId, var: app_id}]
    query: [{name: from, var: from}, {name: recipients, var: recipients, style: multi, required: true}, {name: recipients_cc, var: recipients_cc, style: multi}, {name: recipients_bcc, var: recipients_bcc, style: multi}, {name: title, var: title}, {name: body, var: qp_body}, {name: documents, var: documents, style: multi, required: true}, {name: need_copy_bcc, var: need_copy_bcc}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, from: $from, recipients: $recipients, recipients_cc: $recipients_cc, recipients_bcc: $recipients_bcc, title: $title, qp_body: $qp_body, documents: $documents, need_copy_bcc: $need_copy_bcc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an establishment
#
# DELETE /apps/{appId}/establishments/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.contacts.establishments.delete
export def "app-contacts-establishments-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/establishments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an establishment
#
# GET /apps/{appId}/establishments/{id}
# Returns: record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>>
# operationId: app.contacts.establishments.get
export def "app-contacts-establishments-get" [
  app_id: int
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
    path: "/apps/{appId}/establishments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an establishment
#
# POST /apps/{appId}/establishments/{id}
# Returns: record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>>
# operationId: app.contacts.establishments.update
export def "app-contacts-establishments-update" [
  app_id: int
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
  --name: string
  --phones: list<string>
  --emails: list<string>
  --nic: string # Establishment number (french NIC) (nullable)
  --place: record
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/establishments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: phones, var: phones, style: multi}, {name: emails, var: emails, style: multi}, {name: nic, var: nic}, {name: place, var: place, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, phones: $phones, emails: $emails, nic: $nic, place: $place
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ExportEntity
#
# GET /apps/{appId}/exports
# Returns: table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>
# operationId: app.accounting.export.list
export def "app-accounting-export-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/exports"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a ExportEntity
#
# POST /apps/{appId}/exports
# Returns: record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>
# operationId: app.accounting.export.create
export def "app-accounting-export-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --until: string # required, format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/exports"
    path_params: [{name: appId, var: app_id}]
    query: [{name: until, var: until, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the ACD UUID for authentification
#
# GET /apps/{appId}/exports/acd_compta
# Returns: record<uuid: string>
# operationId: app.accounting.export.AcdComptaGetUuid
export def "app-accounting-export-acd-compta-get-uuid" [
  app_id: int
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
    path: "/apps/{appId}/exports/acd_compta"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register ACD identifiants
#
# POST /apps/{appId}/exports/acd_compta
# Returns: record<uuid: string>
# operationId: app.accounting.export.AcdComptaSetUuid
export def "app-accounting-export-acd-compta-set-uuid" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # the login provided by ACD Compta (required)
  --password: string # the password provided by ACD Compta (required)
  --base: string # Your ACD account number (3XXXX) (required)
  --cnx: string # your CNX by ACD Compta (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/exports/acd_compta"
    path_params: [{name: appId, var: app_id}]
    query: [{name: login, var: login, required: true}, {name: password, var: password, required: true}, {name: base, var: base, required: true}, {name: cnx, var: cnx, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, login: $login, password: $password, base: $base, cnx: $cnx
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the export entity as zip
#
# GET /apps/{appId}/exports/download
# Returns: binary
# operationId: app.accounting.export.download
export def "app-accounting-export-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The export format can be a FEC (universal - similar to the French legal file 'Fichier des Ecritures Comptables') or specific for accounting software
  --export-entities-ids: list<int>
  --start-at: string # Automatically find export entities from a date range (format: date-time)
  --end-at: string # Automatically find export entities from a date range (format: date-time)
  --since: string # Automatically find export entities since a date (format: date-time)
  --since-last: oneof<nothing, bool> # Automatically find the export entities since the last export downloaded
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/exports/download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: format, var: format}, {name: export_entities_ids, var: export_entities_ids, style: multi}, {name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: since, var: since}, {name: since_last, var: since_last}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, format: $format, export_entities_ids: $export_entities_ids, start_at: $start_at, end_at: $end_at, since: $since, since_last: $since_last
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ExportEntity
#
# GET /apps/{appId}/exports/months
# Returns: table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>
# operationId: app.accounting.export.list_by_months
export def "app-accounting-export-list-by-months" [
  app_id: int
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
    path: "/apps/{appId}/exports/months"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a ExportEntity
#
# DELETE /apps/{appId}/exports/{id}
# operationId: app.accounting.export.delete
export def "app-accounting-export-delete" [
  app_id: int
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
    path: "/apps/{appId}/exports/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a ExportEntity
#
# GET /apps/{appId}/exports/{id}
# Returns: record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string>
# operationId: app.accounting.export.get
export def "app-accounting-export-get" [
  app_id: int
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
    path: "/apps/{appId}/exports/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List invoices
#
# GET /apps/{appId}/invoices
# Returns: table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.invoices.list
export def "app-documents-sales-invoices-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/invoices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an invoice
#
# POST /apps/{appId}/invoices
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.invoices.create
export def "app-documents-sales-invoices-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string # nullable
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document (nullable)
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --downpayments: list<int> # nullable
  --downpayment-cash: int # nullable
  --avoid-of: int # nullable
  --delivered-at: string # nullable, format: date-time
  --payment-period: int # Days count before considere this invoice as late (nullable, default: 30)
  --payment-methods: string # Accepted methods of payment for this invoice. Methods comma separated (default: virement bancaire, chèque)
  --number-from-other-software: string # Invoices imported from another software are not counted in the numbering and are not locked
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/invoices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: third_account, var: third_account, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: reference, var: reference}, {name: discount, var: discount, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: downpayments, var: downpayments, style: multi}, {name: downpayment_cash, var: downpayment_cash}, {name: avoid_of, var: avoid_of}, {name: delivered_at, var: delivered_at}, {name: payment_period, var: payment_period}, {name: payment_methods, var: payment_methods}, {name: number_from_other_software, var: number_from_other_software}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, contact_infos: $contact_infos, third_account: $third_account, title: $title, content: $content, columns: $columns, reference: $reference, discount: $discount, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, downpayments: $downpayments, downpayment_cash: $downpayment_cash, avoid_of: $avoid_of, delivered_at: $delivered_at, payment_period: $payment_period, payment_methods: $payment_methods, number_from_other_software: $number_from_other_software
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete many invoices
#
# DELETE /apps/{appId}/invoices/batch
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.sales.invoices.batch_delete
export def "app-documents-sales-invoices-batch-delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of invoices ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/invoices/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update many invoices
#
# POST /apps/{appId}/invoices/batch
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.invoices.batch
export def "app-documents-sales-invoices-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of invoices. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a list of invoices in pdf into a .zip file
#
# GET /apps/{appId}/invoices/download
# Returns: binary
# operationId: app.documents.sales.invoices.download
export def "app-documents-sales-invoices-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of invoices id (required)
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/invoices/download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}, {name: template, var: template}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate pdf and recalcul amounts of invoice
#
# POST /apps/{appId}/invoices/fresh
# Returns: record
# operationId: app.documents.sales.invoices.fresh
export def "app-documents-sales-invoices-fresh" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of invoices id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/fresh"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the next invoice number for preview
#
# GET /apps/{appId}/invoices/nextnumber
# operationId: app.documents.sales.invoices.nextnumber
export def "app-documents-sales-invoices-nextnumber" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --written-at: string # Write date (format: date-time)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/invoices/nextnumber"
    path_params: [{name: appId, var: app_id}]
    query: [{name: written_at, var: written_at}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, written_at: $written_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about invoices
#
# GET /apps/{appId}/invoices/statistics
# Returns: record
# operationId: app.documents.sales.invoices.statistics
export def "app-documents-sales-invoices-statistics" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/invoices/statistics"
    path_params: [{name: appId, var: app_id}]
    query: [{name: search, var: search}, {name: filters, var: filters, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, search: $search, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an invoice
#
# DELETE /apps/{appId}/invoices/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.sales.invoices.delete
export def "app-documents-sales-invoices-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/invoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an invoice
#
# GET /apps/{appId}/invoices/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.invoices.get
export def "app-documents-sales-invoices-get" [
  app_id: int
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
    path: "/apps/{appId}/invoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an invoice
#
# POST /apps/{appId}/invoices/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.invoices.update
export def "app-documents-sales-invoices-update" [
  app_id: int
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
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string # nullable
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document (nullable)
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --downpayments: list<int> # nullable
  --downpayment-cash: int # nullable
  --avoid-of: int # nullable
  --delivered-at: string # nullable, format: date-time
  --payment-period: int # Days count before considere this invoice as late (nullable, default: 30)
  --payment-methods: string # Accepted methods of payment for this invoice. Methods comma separated (default: virement bancaire, chèque)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: third_account, var: third_account, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: reference, var: reference}, {name: discount, var: discount, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: downpayments, var: downpayments, style: multi}, {name: downpayment_cash, var: downpayment_cash}, {name: avoid_of, var: avoid_of}, {name: delivered_at, var: delivered_at}, {name: payment_period, var: payment_period}, {name: payment_methods, var: payment_methods}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, contact_infos: $contact_infos, third_account: $third_account, title: $title, content: $content, columns: $columns, reference: $reference, discount: $discount, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, downpayments: $downpayments, downpayment_cash: $downpayment_cash, avoid_of: $avoid_of, delivered_at: $delivered_at, payment_period: $payment_period, payment_methods: $payment_methods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file at an invoice
#
# DELETE /apps/{appId}/invoices/{id}/attach
# operationId: app.documents.sales.invoices.detach
export def "app-documents-sales-invoices-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/invoices/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file at an invoice
#
# POST /apps/{appId}/invoices/{id}/attach
# operationId: app.documents.sales.invoices.attach
export def "app-documents-sales-invoices-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a creditnote on an invoice
#
# POST /apps/{appId}/invoices/{id}/avoid
# operationId: app.documents.sales.invoices.avoid
export def "app-documents-sales-invoices-avoid" [
  app_id: int
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
    path: "/apps/{appId}/invoices/{id}/avoid"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate an invoice
#
# POST /apps/{appId}/invoices/{id}/duplicate
# operationId: app.documents.sales.invoices.duplicate
export def "app-documents-sales-invoices-duplicate" [
  app_id: int
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
    path: "/apps/{appId}/invoices/{id}/duplicate"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finalize an invoice
#
# POST /apps/{appId}/invoices/{id}/finalize
# operationId: app.documents.sales.invoices.finalize
export def "app-documents-sales-invoices-finalize" [
  app_id: int
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
  --force-date: oneof<nothing, bool> # Automatically updates the date if earlier than the last invoice
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/{id}/finalize"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: force_date, var: force_date}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, force_date: $force_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the invoice as pdf
#
# GET /apps/{appId}/invoices/{id}/pdf
# Returns: binary
# operationId: app.documents.sales.invoices.pdf
export def "app-documents-sales-invoices-pdf" [
  app_id: int
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
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/invoices/{id}/pdf"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: template, var: template}]
    accept: ["application/pdf"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download invoice as jpeg
#
# GET /apps/{appId}/invoices/{id}/preview.jpg
# Returns: binary
# operationId: app.documents.sales.invoices.preview
export def "app-documents-sales-invoices-preview" [
  app_id: int
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
  --template: string # Template name to generate document (nullable)
  --disable-cache: oneof<nothing, bool> # Force the regeneration of the preview (nullable)
  --base64: oneof<nothing, bool> # Get the image in base64 (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/invoices/{id}/preview.jpg"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: template, var: template}, {name: disable_cache, var: disable_cache}, {name: base64, var: base64}]
    accept: ["application/jpeg"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, template: $template, disable_cache: $disable_cache, base64: $base64
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag on an invoice
#
# DELETE /apps/{appId}/invoices/{id}/tag
# operationId: app.documents.sales.invoices.untag
export def "app-documents-sales-invoices-untag" [
  app_id: int
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
  --tag: string # Tag to delete
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/invoices/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tag on an invoice
#
# POST /apps/{appId}/invoices/{id}/tag
# operationId: app.documents.sales.invoices.tag
export def "app-documents-sales-invoices-tag" [
  app_id: int
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
  --tag: string # Tag to add
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the status of an invoice
#
# POST /apps/{appId}/invoices/{id}/updatestatus
# operationId: app.documents.sales.invoices.updatestatus
export def "app-documents-sales-invoices-updatestatus" [
  app_id: int
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
  --status: string@status-completer # Status to update
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/invoices/{id}/updatestatus"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear autoreconciliation logs
#
# DELETE /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.clear
export def "app-cashflow-logsautoreconciliations-clear" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/logs/autoreconcile/"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List autoreconciliation logs
#
# GET /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.list
export def "app-cashflow-logsautoreconciliations-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/logs/autoreconcile/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start force autoreconciliation
#
# POST /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.start
export def "app-cashflow-logsautoreconciliations-start" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/logs/autoreconcile/"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization profile for current app
#
# GET /apps/{appId}/organization
# Returns: table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: any, policies: list, subscription: record, url: string>>
# operationId: app.organization.get
export def "app-organization-get" [
  app_id: int
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
    path: "/apps/{appId}/organization"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization profile for current app
#
# POST /apps/{appId}/organization
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: any, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>>
# operationId: app.organization.update
export def "app-organization-update" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Company name visible on the app
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --trade-directory-registration: string # France Directory Registration : Unique national ID SIRET [0-9]{9} + 'RM' + CMA identification number [0-9a-z]{2,}
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --industry: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --sap-number-registration: string # NOVA agreement/registration number (nullable)
  --sap-activities: string # Organisation activities displayed in annual taxes customer attestation (nullable)
  --sap-date-registration: string # NOVA agreement/registration date (nullable)
  --capital: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/organization"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name}, {name: billing_name, var: billing_name}, {name: logo, var: logo}, {name: legal_form, var: legal_form}, {name: country_iso2, var: country_iso2}, {name: founding_date, var: founding_date}, {name: founding_location, var: founding_location}, {name: dissolution_date, var: dissolution_date}, {name: closeaccounting_period, var: closeaccounting_period}, {name: national_id, var: national_id}, {name: trade_directory_registration, var: trade_directory_registration}, {name: vat_id, var: vat_id}, {name: code_naf, var: code_naf}, {name: number_of_employees, var: number_of_employees}, {name: industry, var: industry}, {name: slogan, var: slogan}, {name: rcs, var: rcs}, {name: greffe, var: greffe}, {name: sap_number_registration, var: sap_number_registration}, {name: sap_activities, var: sap_activities}, {name: sap_date_registration, var: sap_date_registration}, {name: capital, var: capital}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, billing_name: $billing_name, logo: $logo, legal_form: $legal_form, country_iso2: $country_iso2, founding_date: $founding_date, founding_location: $founding_location, dissolution_date: $dissolution_date, closeaccounting_period: $closeaccounting_period, national_id: $national_id, trade_directory_registration: $trade_directory_registration, vat_id: $vat_id, code_naf: $code_naf, number_of_employees: $number_of_employees, industry: $industry, slogan: $slogan, rcs: $rcs, greffe: $greffe, sap_number_registration: $sap_number_registration, sap_activities: $sap_activities, sap_date_registration: $sap_date_registration, capital: $capital
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List organizations
#
# GET /apps/{appId}/organizations
# Returns: table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.list
export def "app-contacts-organizations-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/organizations"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an organization
#
# POST /apps/{appId}/organizations
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.create
export def "app-contacts-organizations-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Company name visible on the app (required)
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --vat-system: string
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --capital: int
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/organizations"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name, required: true}, {name: billing_name, var: billing_name}, {name: logo, var: logo}, {name: legal_form, var: legal_form}, {name: country_iso2, var: country_iso2}, {name: founding_date, var: founding_date}, {name: founding_location, var: founding_location}, {name: dissolution_date, var: dissolution_date}, {name: vat_system, var: vat_system}, {name: closeaccounting_period, var: closeaccounting_period}, {name: national_id, var: national_id}, {name: vat_id, var: vat_id}, {name: code_naf, var: code_naf}, {name: number_of_employees, var: number_of_employees}, {name: slogan, var: slogan}, {name: rcs, var: rcs}, {name: greffe, var: greffe}, {name: capital, var: capital}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, billing_name: $billing_name, logo: $logo, legal_form: $legal_form, country_iso2: $country_iso2, founding_date: $founding_date, founding_location: $founding_location, dissolution_date: $dissolution_date, vat_system: $vat_system, closeaccounting_period: $closeaccounting_period, national_id: $national_id, vat_id: $vat_id, code_naf: $code_naf, number_of_employees: $number_of_employees, slogan: $slogan, rcs: $rcs, greffe: $greffe, capital: $capital, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple organizations
#
# POST /apps/{appId}/organizations/batch
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.batch
export def "app-contacts-organizations-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of invoices. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/organizations/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an organization
#
# DELETE /apps/{appId}/organizations/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.contacts.organizations.delete
export def "app-contacts-organizations-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/organizations/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization
#
# GET /apps/{appId}/organizations/{id}
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.get
export def "app-contacts-organizations-get" [
  app_id: int
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
    path: "/apps/{appId}/organizations/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an organization
#
# POST /apps/{appId}/organizations/{id}
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.update
export def "app-contacts-organizations-update" [
  app_id: int
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
  --name: string # Company name visible on the app
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --vat-system: string
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --capital: int
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/organizations/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: billing_name, var: billing_name}, {name: logo, var: logo}, {name: legal_form, var: legal_form}, {name: country_iso2, var: country_iso2}, {name: founding_date, var: founding_date}, {name: founding_location, var: founding_location}, {name: dissolution_date, var: dissolution_date}, {name: vat_system, var: vat_system}, {name: closeaccounting_period, var: closeaccounting_period}, {name: national_id, var: national_id}, {name: vat_id, var: vat_id}, {name: code_naf, var: code_naf}, {name: number_of_employees, var: number_of_employees}, {name: slogan, var: slogan}, {name: rcs, var: rcs}, {name: greffe, var: greffe}, {name: capital, var: capital}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, billing_name: $billing_name, logo: $logo, legal_form: $legal_form, country_iso2: $country_iso2, founding_date: $founding_date, founding_location: $founding_location, dissolution_date: $dissolution_date, vat_system: $vat_system, closeaccounting_period: $closeaccounting_period, national_id: $national_id, vat_id: $vat_id, code_naf: $code_naf, number_of_employees: $number_of_employees, slogan: $slogan, rcs: $rcs, greffe: $greffe, capital: $capital, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore an organization
#
# GET /apps/{appId}/organizations/{id}/restore
# Returns: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>
# operationId: app.contacts.organizations.restore
export def "app-contacts-organizations-restore" [
  app_id: int
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
    path: "/apps/{appId}/organizations/{id}/restore"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List payments
#
# GET /apps/{appId}/payments
# Returns: table<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record, cashflow_source: record, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list, method: int, received_at: string, updated_at: string>>
# operationId: app.payments.payments.list
export def "app-payments-payments-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/payments"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the recipe book
#
# GET /apps/{appId}/payments/recipe_book
# operationId: app.payments.payments.recipe_book
export def "app-payments-payments-recipe-book" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/payments/recipe_book"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a payment
#
# DELETE /apps/{appId}/payments/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.payments.payments.delete
export def "app-payments-payments-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/payments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a payment
#
# GET /apps/{appId}/payments/{id}
# Returns: record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>>
# operationId: app.payments.payments.get
export def "app-payments-payments-get" [
  app_id: int
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
    path: "/apps/{appId}/payments/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List persons
#
# GET /apps/{appId}/persons
# Returns: table<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.list
export def "app-contacts-persons-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/persons"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a person
#
# POST /apps/{appId}/persons
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.create
export def "app-contacts-persons-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --civility: string # Civility is the lastname prefix
  --lastname: string # required
  --firstname: string
  --picture: string
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/persons"
    path_params: [{name: appId, var: app_id}]
    query: [{name: civility, var: civility}, {name: lastname, var: lastname, required: true}, {name: firstname, var: firstname}, {name: picture, var: picture}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, civility: $civility, lastname: $lastname, firstname: $firstname, picture: $picture, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple persons
#
# POST /apps/{appId}/persons/batch
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.batch
export def "app-contacts-persons-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of persons. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/persons/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a person
#
# DELETE /apps/{appId}/persons/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.contacts.persons.delete
export def "app-contacts-persons-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/persons/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a person
#
# GET /apps/{appId}/persons/{id}
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.get
export def "app-contacts-persons-get" [
  app_id: int
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
    path: "/apps/{appId}/persons/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a person
#
# POST /apps/{appId}/persons/{id}
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.update
export def "app-contacts-persons-update" [
  app_id: int
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
  --civility: string # Civility is the lastname prefix (nullable)
  --lastname: string
  --firstname: string
  --picture: string
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/persons/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: civility, var: civility}, {name: lastname, var: lastname}, {name: firstname, var: firstname}, {name: picture, var: picture}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, civility: $civility, lastname: $lastname, firstname: $firstname, picture: $picture, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore a person
#
# GET /apps/{appId}/persons/{id}/restore
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>>
# operationId: app.contacts.persons.restore
export def "app-contacts-persons-restore" [
  app_id: int
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
    path: "/apps/{appId}/persons/{id}/restore"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping app web hostname
#
# GET /apps/{appId}/ping
# operationId: app.ping
export def "app-ping" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/ping"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List product categories
#
# GET /apps/{appId}/productcategory
# Returns: table<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>>
# operationId: app.catalog.categories.list
export def "app-catalog-categories-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/productcategory"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a product category
#
# POST /apps/{appId}/productcategory
# Returns: record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>
# operationId: app.catalog.categories.create
export def "app-catalog-categories-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # required
  --image: string
  --parent-category-id: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productcategory"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name, required: true}, {name: image, var: image}, {name: parent_category_id, var: parent_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, image: $image, parent_category_id: $parent_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a product category
#
# DELETE /apps/{appId}/productcategory/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.catalog.categories.delete
export def "app-catalog-categories-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/productcategory/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product category
#
# GET /apps/{appId}/productcategory/{id}
# Returns: record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>
# operationId: app.catalog.categories.get
export def "app-catalog-categories-get" [
  app_id: int
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
    path: "/apps/{appId}/productcategory/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a product category
#
# POST /apps/{appId}/productcategory/{id}
# Returns: record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>>
# operationId: app.catalog.categories.update
export def "app-catalog-categories-update" [
  app_id: int
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
  --name: string # required
  --image: string
  --parent-category-id: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productcategory/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name, required: true}, {name: image, var: image}, {name: parent_category_id, var: parent_category_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, image: $image, parent_category_id: $parent_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List products
#
# GET /apps/{appId}/products
# Returns: table<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>
# operationId: app.catalog.products.list
export def "app-catalog-products-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/products"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a product
#
# POST /apps/{appId}/products
# Returns: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>
# operationId: app.catalog.products.create
export def "app-catalog-products-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # required
  --amount: int # Price without taxes in cents
  --amount-accurately: int # Price without taxes in cents / 1000
  --vat-percent: int # Taxe rate in cents
  --image: string
  --lifetime: int # Product life time in seconds
  --description: string # Product description
  --type: string@type-completer-3 # Is a service or a product ?
  --quantity-name: string # Name of the quantity: days, liters, m2, m3...
  --reference: string
  --account-id: string
  --tags: list
  --category-id: int
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/products"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name, required: true}, {name: amount, var: amount}, {name: amount_accurately, var: amount_accurately}, {name: vat_percent, var: vat_percent}, {name: image, var: image}, {name: lifetime, var: lifetime}, {name: description, var: description}, {name: type, var: type}, {name: quantity_name, var: quantity_name}, {name: reference, var: reference}, {name: account_id, var: account_id}, {name: tags, var: tags, style: multi}, {name: category_id, var: category_id}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, amount: $amount, amount_accurately: $amount_accurately, vat_percent: $vat_percent, image: $image, lifetime: $lifetime, description: $description, type: $type, quantity_name: $quantity_name, reference: $reference, account_id: $account_id, tags: $tags, category_id: $category_id, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple products
#
# POST /apps/{appId}/products/batch
# Returns: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>
# operationId: app.catalog.products.batch
export def "app-catalog-products-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of products. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/products/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a product
#
# DELETE /apps/{appId}/products/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.catalog.products.delete
export def "app-catalog-products-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/products/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product
#
# GET /apps/{appId}/products/{id}
# Returns: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>
# operationId: app.catalog.products.get
export def "app-catalog-products-get" [
  app_id: int
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
    path: "/apps/{appId}/products/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a product
#
# POST /apps/{appId}/products/{id}
# Returns: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>
# operationId: app.catalog.products.update
export def "app-catalog-products-update" [
  app_id: int
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
  --name: string
  --amount: int # Price without taxes in cents
  --amount-accurately: int # Price without taxes in cents / 1000
  --vat-percent: int # Taxe rate in cents
  --image: string
  --lifetime: int # Product life time in seconds
  --description: string # Product description
  --type: string@type-completer-3 # Is a service or a product ?
  --quantity-name: string # Name of the quantity: days, liters, m2, m3...
  --reference: string
  --account-id: string
  --tags: list
  --category-id: int
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/products/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: amount, var: amount}, {name: amount_accurately, var: amount_accurately}, {name: vat_percent, var: vat_percent}, {name: image, var: image}, {name: lifetime, var: lifetime}, {name: description, var: description}, {name: type, var: type}, {name: quantity_name, var: quantity_name}, {name: reference, var: reference}, {name: account_id, var: account_id}, {name: tags, var: tags, style: multi}, {name: category_id, var: category_id}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, amount: $amount, amount_accurately: $amount_accurately, vat_percent: $vat_percent, image: $image, lifetime: $lifetime, description: $description, type: $type, quantity_name: $quantity_name, reference: $reference, account_id: $account_id, tags: $tags, category_id: $category_id, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file
#
# DELETE /apps/{appId}/products/{id}/attach
# operationId: app.catalog.products.detach
export def "app-catalog-products-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/products/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file
#
# POST /apps/{appId}/products/{id}/attach
# operationId: app.catalog.products.attach
export def "app-catalog-products-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/products/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List stocks
#
# GET /apps/{appId}/productstocks
# Returns: table<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>, product_stocks_movements: list<record>, purchase: record<account: record, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record, supplier_name: string, tags: list, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: list<record>, use_duration: int>
# operationId: app.catalog.stocks.list
export def "app-catalog-stocks-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/productstocks"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a stocks
#
# POST /apps/{appId}/productstocks
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.create
export def "app-catalog-stocks-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: int # Parent object (required)
  --purchase-id: int # Purchase that generated the stock if exists
  --quantity: int # The initial quantity will no longer be modifiable. To change the quantity manually, use the `destruct` endpoint
  --bar-code: string
  --location: string
  --entered-at: string # format: date-time
  --expired-at: string # format: date-time
  --cost-amount: int
  --use-duration: int # Use duration in seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productstocks"
    path_params: [{name: appId, var: app_id}]
    query: [{name: product_id, var: product_id, required: true}, {name: purchase_id, var: purchase_id}, {name: quantity, var: quantity}, {name: bar_code, var: bar_code}, {name: location, var: location}, {name: entered_at, var: entered_at}, {name: expired_at, var: expired_at}, {name: cost_amount, var: cost_amount}, {name: use_duration, var: use_duration}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, product_id: $product_id, purchase_id: $purchase_id, quantity: $quantity, bar_code: $bar_code, location: $location, entered_at: $entered_at, expired_at: $expired_at, cost_amount: $cost_amount, use_duration: $use_duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a stocks
#
# DELETE /apps/{appId}/productstocks/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.catalog.stocks.delete
export def "app-catalog-stocks-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/productstocks/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a stocks
#
# GET /apps/{appId}/productstocks/{id}
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.get
export def "app-catalog-stocks-get" [
  app_id: int
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
    path: "/apps/{appId}/productstocks/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a stocks
#
# POST /apps/{appId}/productstocks/{id}
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.update
export def "app-catalog-stocks-update" [
  app_id: int
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
  --purchase-id: int # Purchase that generated the stock if exists
  --bar-code: string
  --location: string
  --entered-at: string # format: date-time
  --expired-at: string # format: date-time
  --cost-amount: int
  --use-duration: int # Use duration in seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productstocks/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: purchase_id, var: purchase_id}, {name: bar_code, var: bar_code}, {name: location, var: location}, {name: entered_at, var: entered_at}, {name: expired_at, var: expired_at}, {name: cost_amount, var: cost_amount}, {name: use_duration, var: use_duration}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, purchase_id: $purchase_id, bar_code: $bar_code, location: $location, entered_at: $entered_at, expired_at: $expired_at, cost_amount: $cost_amount, use_duration: $use_duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Destruct a quantity of stock (forgotten, destructed, expirated stock...)
#
# POST /apps/{appId}/productstocks/{id}/destruct
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.destruct
export def "app-catalog-stocks-destruct" [
  app_id: int
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
  --quantity: int # Quantity to destruct
  --comment: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productstocks/{id}/destruct"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: quantity, var: quantity}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, quantity: $quantity, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Consider part of the stock as back
#
# POST /apps/{appId}/productstocks/{id}/rental/back
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.rental_back
export def "app-catalog-stocks-rental-back" [
  app_id: int
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
  --quantity: int # Quantity to return in stocks (required)
  --current-return-date: string # format: date-time, default: now
  --use-duration: int # Usage duration in seconds (default: 0)
  --comment: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productstocks/{id}/rental/back"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: quantity, var: quantity, required: true}, {name: current_return_date, var: current_return_date}, {name: use_duration, var: use_duration}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, quantity: $quantity, current_return_date: $current_return_date, use_duration: $use_duration, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Consider part of the stock as rented
#
# POST /apps/{appId}/productstocks/{id}/rental/exit
# Returns: record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int>
# operationId: app.catalog.stocks.rental_exit
export def "app-catalog-stocks-rental-exit" [
  app_id: int
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
  --quantity: int # Quantity to rent
  --future-return-date: string # format: date-time
  --comment: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/productstocks/{id}/rental/exit"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: quantity, var: quantity}, {name: future_return_date, var: future_return_date}, {name: comment, var: comment}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, quantity: $quantity, future_return_date: $future_return_date, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List purchases
#
# GET /apps/{appId}/purchases
# Returns: table<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>
# operationId: app.documents.purchases.purchases.list
export def "app-documents-purchases-purchases-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
  --expand: list<string>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/purchases"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}, {name: expand, var: expand, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a purchase
#
# POST /apps/{appId}/purchases
# Returns: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>
# operationId: app.documents.purchases.purchases.create
export def "app-documents-purchases-purchases-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoice: string # Invoice or receipt file (pdf or image) (format: binary)
  --account-id: int
  --supplier-organization-id: int
  --title: string
  --supplier-name: string
  --amount: int
  --amount-tax: int
  --currency: string
  --vat-detail: record
  --billed-at: string # format: date
  --comment: int
  --tags: list
  --vat-repayment: string@vat-repayment-completer
  --payment-deadline-at: string # nullable, format: date
  --payment-account-number: string # nullable
  --payment-routing-number: string # nullable
  --payment-swift: string # nullable
  --payment-iban: string # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/purchases"
    path_params: [{name: appId, var: app_id}]
    query: [{name: invoice, var: invoice}, {name: account_id, var: account_id}, {name: supplier_organization_id, var: supplier_organization_id}, {name: title, var: title}, {name: supplier_name, var: supplier_name}, {name: amount, var: amount}, {name: amount_tax, var: amount_tax}, {name: currency, var: currency}, {name: vat_detail, var: vat_detail, style: multi}, {name: billed_at, var: billed_at}, {name: comment, var: comment}, {name: tags, var: tags, style: multi}, {name: vat_repayment, var: vat_repayment}, {name: payment_deadline_at, var: payment_deadline_at}, {name: payment_account_number, var: payment_account_number}, {name: payment_routing_number, var: payment_routing_number}, {name: payment_swift, var: payment_swift}, {name: payment_iban, var: payment_iban}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, invoice: $invoice, account_id: $account_id, supplier_organization_id: $supplier_organization_id, title: $title, supplier_name: $supplier_name, amount: $amount, amount_tax: $amount_tax, currency: $currency, vat_detail: $vat_detail, billed_at: $billed_at, comment: $comment, tags: $tags, vat_repayment: $vat_repayment, payment_deadline_at: $payment_deadline_at, payment_account_number: $payment_account_number, payment_routing_number: $payment_routing_number, payment_swift: $payment_swift, payment_iban: $payment_iban
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete many purchases
#
# DELETE /apps/{appId}/purchases/batch
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.purchases.purchases.batch_delete
export def "app-documents-purchases-purchases-batch-delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of purchases ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/purchases/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update many purchases
#
# POST /apps/{appId}/purchases/batch
# Returns: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>
# operationId: app.documents.purchases.purchases.batch
export def "app-documents-purchases-purchases-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of purchases. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/purchases/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a list of purchases in pdf into a .zip file
#
# GET /apps/{appId}/purchases/download
# Returns: binary
# operationId: app.documents.purchases.purchases.download
export def "app-documents-purchases-purchases-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of purchases id (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/purchases/download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about purchases
#
# GET /apps/{appId}/purchases/statistics
# Returns: record
# operationId: app.documents.purchases.purchases.statistics
export def "app-documents-purchases-purchases-statistics" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/purchases/statistics"
    path_params: [{name: appId, var: app_id}]
    query: [{name: search, var: search}, {name: filters, var: filters, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, search: $search, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a purchase
#
# DELETE /apps/{appId}/purchases/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.purchases.purchases.delete
export def "app-documents-purchases-purchases-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/purchases/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a purchase
#
# GET /apps/{appId}/purchases/{id}
# Returns: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>
# operationId: app.documents.purchases.purchases.get
export def "app-documents-purchases-purchases-get" [
  app_id: int
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
    path: "/apps/{appId}/purchases/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a purchase
#
# POST /apps/{appId}/purchases/{id}
# Returns: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>
# operationId: app.documents.purchases.purchases.update
export def "app-documents-purchases-purchases-update" [
  app_id: int
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
  --account-id: int # Auto-calculated by sales_lines total
  --supplier-organization-id: int
  --title: string
  --supplier-name: string
  --amount: int # Auto-calculated by sales_lines total
  --amount-tax: int
  --currency: string
  --vat-detail: record
  --billed-at: string # format: date
  --comment: int
  --tags: list
  --vat-repayment: string@vat-repayment-completer
  --payment-deadline-at: string # nullable, format: date
  --payment-account-number: string # nullable
  --payment-routing-number: string # nullable
  --payment-swift: string # nullable
  --payment-iban: string # nullable
  --purchase-lines: list
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/purchases/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: account_id, var: account_id}, {name: supplier_organization_id, var: supplier_organization_id}, {name: title, var: title}, {name: supplier_name, var: supplier_name}, {name: amount, var: amount}, {name: amount_tax, var: amount_tax}, {name: currency, var: currency}, {name: vat_detail, var: vat_detail, style: multi}, {name: billed_at, var: billed_at}, {name: comment, var: comment}, {name: tags, var: tags, style: multi}, {name: vat_repayment, var: vat_repayment}, {name: payment_deadline_at, var: payment_deadline_at}, {name: payment_account_number, var: payment_account_number}, {name: payment_routing_number, var: payment_routing_number}, {name: payment_swift, var: payment_swift}, {name: payment_iban, var: payment_iban}, {name: purchase_lines, var: purchase_lines, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, account_id: $account_id, supplier_organization_id: $supplier_organization_id, title: $title, supplier_name: $supplier_name, amount: $amount, amount_tax: $amount_tax, currency: $currency, vat_detail: $vat_detail, billed_at: $billed_at, comment: $comment, tags: $tags, vat_repayment: $vat_repayment, payment_deadline_at: $payment_deadline_at, payment_account_number: $payment_account_number, payment_routing_number: $payment_routing_number, payment_swift: $payment_swift, payment_iban: $payment_iban, purchase_lines: $purchase_lines
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file at a purchase
#
# DELETE /apps/{appId}/purchases/{id}/attach
# operationId: app.documents.purchases.purchases.detach
export def "app-documents-purchases-purchases-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/purchases/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file at a purchase
#
# POST /apps/{appId}/purchases/{id}/attach
# operationId: app.documents.purchases.purchases.attach
export def "app-documents-purchases-purchases-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/purchases/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the purchase as pdf
#
# GET /apps/{appId}/purchases/{id}/original
# Returns: binary
# operationId: app.documents.purchases.purchases.original
export def "app-documents-purchases-purchases-original" [
  app_id: int
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
    method: get
    path: "/apps/{appId}/purchases/{id}/original"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download purchase as jpeg
#
# GET /apps/{appId}/purchases/{id}/preview.jpg
# Returns: binary
# operationId: app.documents.purchases.purchases.preview
export def "app-documents-purchases-purchases-preview" [
  app_id: int
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
    method: get
    path: "/apps/{appId}/purchases/{id}/preview.jpg"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/jpeg"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag on a purchase
#
# DELETE /apps/{appId}/purchases/{id}/tag
# operationId: app.documents.purchases.purchases.untag
export def "app-documents-purchases-purchases-untag" [
  app_id: int
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
  --tag: string # Tag to delete
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/purchases/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tag on a purchase
#
# POST /apps/{appId}/purchases/{id}/tag
# operationId: app.documents.purchases.purchases.tag
export def "app-documents-purchases-purchases-tag" [
  app_id: int
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
  --tag: string # Tag to add
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/purchases/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show purchase thumbnail as jpeg
#
# GET /apps/{appId}/purchases/{id}/thumbnail.jpg
# Returns: binary
# operationId: app.documents.purchases.purchases.thumbnail
export def "app-documents-purchases-purchases-thumbnail" [
  app_id: int
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
    method: get
    path: "/apps/{appId}/purchases/{id}/thumbnail.jpg"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/jpeg"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the status of an invoice
#
# POST /apps/{appId}/purchases/{id}/updatestatus
# operationId: app.documents.purchases.purchases.updatestatus
export def "app-documents-purchases-purchases-updatestatus" [
  app_id: int
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
  --status: string@status-completer-1 # Status to update
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/purchases/{id}/updatestatus"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List quotes
#
# GET /apps/{appId}/quotes
# Returns: table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.list
export def "app-documents-sales-quotes-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/quotes"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a quote
#
# POST /apps/{appId}/quotes
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.create
export def "app-documents-sales-quotes-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list
  --metadata: list # nullable
  --downpayment-request: record
  --commercialvalidity-deadline: string # nullable, format: date-time
  --number-from-other-software: string # Invoices imported from another software are not counted in the numbering and are not locked
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes"
    path_params: [{name: appId, var: app_id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: third_account, var: third_account, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: reference, var: reference}, {name: discount, var: discount, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: downpayment_request, var: downpayment_request, style: multi}, {name: commercialvalidity_deadline, var: commercialvalidity_deadline}, {name: number_from_other_software, var: number_from_other_software}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, contact_infos: $contact_infos, third_account: $third_account, title: $title, content: $content, columns: $columns, reference: $reference, discount: $discount, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, downpayment_request: $downpayment_request, commercialvalidity_deadline: $commercialvalidity_deadline, number_from_other_software: $number_from_other_software
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete many quotes
#
# DELETE /apps/{appId}/quotes/batch
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.sales.quotes.batch_delete
export def "app-documents-sales-quotes-batch-delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of quotes ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/quotes/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update many quotes
#
# POST /apps/{appId}/quotes/batch
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.batch
export def "app-documents-sales-quotes-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of quotes. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a list of quotes in pdf into a .zip file
#
# GET /apps/{appId}/quotes/download
# Returns: binary
# operationId: app.documents.sales.quotes.download
export def "app-documents-sales-quotes-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id (required)
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/download"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}, {name: template, var: template}]
    accept: ["application/zip"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate pdf and recalcul amounts of quote
#
# POST /apps/{appId}/quotes/fresh
# Returns: record
# operationId: app.documents.sales.quotes.fresh
export def "app-documents-sales-quotes-fresh" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/fresh"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update many quotes
#
# POST /apps/{appId}/quotes/invoice
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.quotes.invoices
export def "app-documents-sales-quotes-invoices" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/invoice"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the next quote number for preview
#
# GET /apps/{appId}/quotes/nextnumber
# operationId: app.documents.sales.quotes.nextnumber
export def "app-documents-sales-quotes-nextnumber" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --written-at: string # Write date (format: date-time)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/nextnumber"
    path_params: [{name: appId, var: app_id}]
    query: [{name: written_at, var: written_at}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, written_at: $written_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about quotes
#
# GET /apps/{appId}/quotes/statistics
# Returns: record
# operationId: app.documents.sales.quotes.statistics
export def "app-documents-sales-quotes-statistics" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/statistics"
    path_params: [{name: appId, var: app_id}]
    query: [{name: search, var: search}, {name: filters, var: filters, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, search: $search, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a quote
#
# DELETE /apps/{appId}/quotes/{id}
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.sales.quotes.delete
export def "app-documents-sales-quotes-delete" [
  app_id: int
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
    method: delete
    path: "/apps/{appId}/quotes/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a quote
#
# GET /apps/{appId}/quotes/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.get
export def "app-documents-sales-quotes-get" [
  app_id: int
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
    path: "/apps/{appId}/quotes/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a quote
#
# POST /apps/{appId}/quotes/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.update
export def "app-documents-sales-quotes-update" [
  app_id: int
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
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list
  --metadata: list # nullable
  --downpayment-request: record
  --commercialvalidity-deadline: string # nullable, format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: third_account, var: third_account, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: reference, var: reference}, {name: discount, var: discount, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: downpayment_request, var: downpayment_request, style: multi}, {name: commercialvalidity_deadline, var: commercialvalidity_deadline}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, contact_infos: $contact_infos, third_account: $third_account, title: $title, content: $content, columns: $columns, reference: $reference, discount: $discount, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, downpayment_request: $downpayment_request, commercialvalidity_deadline: $commercialvalidity_deadline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file at a quote
#
# DELETE /apps/{appId}/quotes/{id}/attach
# operationId: app.documents.sales.quotes.detach
export def "app-documents-sales-quotes-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/quotes/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file at a quote
#
# POST /apps/{appId}/quotes/{id}/attach
# operationId: app.documents.sales.quotes.attach
export def "app-documents-sales-quotes-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transform the quote in a downpayment invoice
#
# POST /apps/{appId}/quotes/{id}/downpayment
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.quotes.downpayment
export def "app-documents-sales-quotes-downpayment" [
  app_id: int
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
  --percent: int # Percentage of downpayment in cents (100 = 1%) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}/downpayment"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: percent, var: percent, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, percent: $percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate a quote
#
# POST /apps/{appId}/quotes/{id}/duplicate
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.documents.sales.quotes.duplicate
export def "app-documents-sales-quotes-duplicate" [
  app_id: int
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
    method: post
    path: "/apps/{appId}/quotes/{id}/duplicate"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finalize a quote
#
# POST /apps/{appId}/quotes/{id}/finalize
# operationId: app.documents.sales.quotes.finalize
export def "app-documents-sales-quotes-finalize" [
  app_id: int
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
    path: "/apps/{appId}/quotes/{id}/finalize"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transform the quote in invoice
#
# POST /apps/{appId}/quotes/{id}/invoice
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.quotes.invoice
export def "app-documents-sales-quotes-invoice" [
  app_id: int
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
    method: post
    path: "/apps/{appId}/quotes/{id}/invoice"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the quote as pdf
#
# GET /apps/{appId}/quotes/{id}/pdf
# Returns: binary
# operationId: app.documents.sales.quotes.pdf
export def "app-documents-sales-quotes-pdf" [
  app_id: int
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
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/{id}/pdf"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: template, var: template}]
    accept: ["application/pdf"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download quote as jpeg
#
# GET /apps/{appId}/quotes/{id}/preview.jpg
# Returns: binary
# operationId: app.documents.sales.quotes.preview
export def "app-documents-sales-quotes-preview" [
  app_id: int
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
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/{id}/preview.jpg"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: template, var: template}]
    accept: ["application/jpeg"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transform the quote into a situation invoice
#
# POST /apps/{appId}/quotes/{id}/situation_invoice
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.quotes.situation_invoice
export def "app-documents-sales-quotes-situation-invoice" [
  app_id: int
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
  --progress: int # Percentage of progress in cents (100 = 1%) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}/situation_invoice"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: progress, var: progress, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, progress: $progress
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag on a quote
#
# DELETE /apps/{appId}/quotes/{id}/tag
# operationId: app.documents.sales.quotes.untag
export def "app-documents-sales-quotes-untag" [
  app_id: int
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
  --tag: string # Tag to delete
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/quotes/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tag on an quote
#
# POST /apps/{appId}/quotes/{id}/tag
# operationId: app.documents.sales.quotes.tag
export def "app-documents-sales-quotes-tag" [
  app_id: int
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
  --tag: string # Tag to add
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}/tag"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the status of a quote
#
# POST /apps/{appId}/quotes/{id}/updatestatus
# operationId: app.documents.sales.quotes.updatestatus
export def "app-documents-sales-quotes-updatestatus" [
  app_id: int
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
  --status: string@status-completer-2 # Status to update
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/quotes/{id}/updatestatus"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download quote as jpeg
#
# GET /apps/{appId}/quotes/{id}/yousign/preview.jpg
# Returns: binary
# operationId: app.documents.sales.quotes.yousign_preview
export def "app-documents-sales-quotes-yousign-preview" [
  app_id: int
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
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/quotes/{id}/yousign/preview.jpg"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: template, var: template}]
    accept: ["application/jpeg"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, id: $id, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove payments by an object
#
# DELETE /apps/{appId}/reconcile
# Returns: record<code: int, message: string, type: string>
# operationId: app.payments.reconciliation.unreconcile
export def "app-payments-reconciliation-unreconcile" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-4 # Object to unpay with this payment (required)
  --id: int # Transaction, sales invoice or purchase invoice id to unreconcile (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/reconcile"
    path_params: [{name: appId, var: app_id}]
    query: [{name: type, var: type, required: true}, {name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, type: $type, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconcile a transaction or a document
#
# POST /apps/{appId}/reconcile
# Returns: record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>>
# operationId: app.payments.reconciliation.reconcile
export def "app-payments-reconciliation-reconcile" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-all: oneof<nothing, bool> # Remove all previous reconciliations (default: false)
  --type: string@type-completer-4 # Object to pay with these payments and categorizations (required)
  --id: int # Transaction, sales invoice or purchase invoice id to reconcile (required)
  --movements: record # required
  --paid-at: string # Payment date for cashdesk or waiting entries (format: date-time)
  --rule: record # Create an auto-reconciliation rule
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/reconcile"
    path_params: [{name: appId, var: app_id}]
    query: [{name: replace_all, var: replace_all}, {name: type, var: type, required: true}, {name: id, var: id, required: true}, {name: movements, var: movements, style: multi, required: true}, {name: paid_at, var: paid_at}, {name: rule, var: rule, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, replace_all: $replace_all, type: $type, id: $id, movements: $movements, paid_at: $paid_at, rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reconcile several transactions
#
# POST /apps/{appId}/reconcile/batch
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>
# operationId: app.payments.reconciliation.batch
export def "app-payments-reconciliation-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # array of reconciliation params (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/reconcile/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List RecurringInvoice
#
# GET /apps/{appId}/recurringinvoices
# Returns: table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>
# operationId: app.documents.sales.recurringinvoices.list
export def "app-documents-sales-recurringinvoices-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/recurringinvoices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>
# operationId: app.documents.sales.recurringinvoices.create
export def "app-documents-sales-recurringinvoices-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --title: string # nullable
  --content: list # nullable
  --columns: record # List columns to display
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --payment-period: int # Days count before considere this invoice as late (default: 30)
  --next-invoice-at: string # nullable, format: date-time
  --end-at: string # nullable, format: date-time
  --frequency-count: int # required
  --frequency-duration: string@frequency-duration-completer # required
  --discount: int
  --discount-mode: string@discount-mode-completer # nullable
  --discount-start-at: string # nullable, format: date-time
  --discount-end-at: string # nullable, format: date-time
  --details: string # nullable
  --orders-plan: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/recurringinvoices"
    path_params: [{name: appId, var: app_id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: payment_period, var: payment_period}, {name: next_invoice_at, var: next_invoice_at}, {name: end_at, var: end_at}, {name: frequency_count, var: frequency_count, required: true}, {name: frequency_duration, var: frequency_duration, required: true}, {name: discount, var: discount}, {name: discount_mode, var: discount_mode}, {name: discount_start_at, var: discount_start_at}, {name: discount_end_at, var: discount_end_at}, {name: details, var: details}, {name: orders_plan, var: orders_plan, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, contact_infos: $contact_infos, title: $title, content: $content, columns: $columns, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, payment_period: $payment_period, next_invoice_at: $next_invoice_at, end_at: $end_at, frequency_count: $frequency_count, frequency_duration: $frequency_duration, discount: $discount, discount_mode: $discount_mode, discount_start_at: $discount_start_at, discount_end_at: $discount_end_at, details: $details, orders_plan: $orders_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete many RecurringInvoice
#
# DELETE /apps/{appId}/recurringinvoices/batch
# Returns: record<code: int, message: string, type: string>
# operationId: app.documents.sales.recurringinvoices.batch_delete
export def "app-documents-sales-recurringinvoices-batch-delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of RecurringInvoice ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/apps/{appId}/recurringinvoices/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update many RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices/batch
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>
# operationId: app.documents.sales.recurringinvoices.batch
export def "app-documents-sales-recurringinvoices-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of RecurringInvoice. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/recurringinvoices/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get json of periods_formats for a date.
#
# GET /apps/{appId}/recurringinvoices/periods
# Returns: list<any>
# operationId: app.documents.sales.recurringinvoices.getPeriods
export def "app-documents-sales-recurringinvoices-get-periods" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of the invoice (nullable, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/recurringinvoices/periods"
    path_params: [{name: appId, var: app_id}]
    query: [{name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a RecurringInvoice
#
# DELETE /apps/{appId}/recurringinvoices/{id}
# operationId: app.documents.sales.recurringinvoices.delete
export def "app-documents-sales-recurringinvoices-delete" [
  app_id: int
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
    path: "/apps/{appId}/recurringinvoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a RecurringInvoice
#
# GET /apps/{appId}/recurringinvoices/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>
# operationId: app.documents.sales.recurringinvoices.get
export def "app-documents-sales-recurringinvoices-get" [
  app_id: int
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
    path: "/apps/{appId}/recurringinvoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices/{id}
# Returns: record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string>
# operationId: app.documents.sales.recurringinvoices.update
export def "app-documents-sales-recurringinvoices-update" [
  app_id: int
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
  --contact-infos: record # nullable
  --title: string # nullable
  --content: list # nullable
  --columns: record # List columns to display
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --payment-period: int # Days count before considere this invoice as late (default: 30)
  --next-invoice-at: string # nullable, format: date-time
  --end-at: string # nullable, format: date-time
  --frequency-count: int
  --frequency-duration: string@frequency-duration-completer
  --discount: int
  --discount-mode: string@discount-mode-completer # nullable
  --discount-start-at: string # nullable, format: date-time
  --discount-end-at: string # nullable, format: date-time
  --details: string # nullable
  --orders-plan: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/recurringinvoices/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: contact_infos, var: contact_infos, style: multi}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}, {name: currency, var: currency}, {name: legal_notice, var: legal_notice}, {name: bank_details_id, var: bank_details_id}, {name: vat_exemption, var: vat_exemption, style: multi}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: payment_period, var: payment_period}, {name: next_invoice_at, var: next_invoice_at}, {name: end_at, var: end_at}, {name: frequency_count, var: frequency_count}, {name: frequency_duration, var: frequency_duration}, {name: discount, var: discount}, {name: discount_mode, var: discount_mode}, {name: discount_start_at, var: discount_start_at}, {name: discount_end_at, var: discount_end_at}, {name: details, var: details}, {name: orders_plan, var: orders_plan, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, contact_infos: $contact_infos, title: $title, content: $content, columns: $columns, currency: $currency, legal_notice: $legal_notice, bank_details_id: $bank_details_id, vat_exemption: $vat_exemption, tags: $tags, metadata: $metadata, payment_period: $payment_period, next_invoice_at: $next_invoice_at, end_at: $end_at, frequency_count: $frequency_count, frequency_duration: $frequency_duration, discount: $discount, discount_mode: $discount_mode, discount_start_at: $discount_start_at, discount_end_at: $discount_end_at, details: $details, orders_plan: $orders_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview next invoices generations
#
# GET /apps/{appId}/recurringinvoices/{id}/plan
# Returns: table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string>
# operationId: app.documents.sales.recurringinvoices.plan
export def "app-documents-sales-recurringinvoices-plan" [
  app_id: int
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
  --until: string # Until date to generate plan (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/recurringinvoices/{id}/plan"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: until, var: until, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List relationships
#
# GET /apps/{appId}/relationships
# Returns: table<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>
# operationId: app.contacts.relationships.list
export def "app-contacts-relationships-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/relationships"
    path_params: [{name: appId, var: app_id}]
    query: [{name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a relationship
#
# GET /apps/{appId}/relationships/{id}
# Returns: record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>
# operationId: app.contacts.relationships.get
export def "app-contacts-relationships-get" [
  app_id: int
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
    path: "/apps/{appId}/relationships/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a relationship
#
# POST /apps/{appId}/relationships/{id}
# Returns: record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int>
# operationId: app.contacts.relationships.update
export def "app-contacts-relationships-update" [
  app_id: int
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
  --is-customer: oneof<nothing, bool>
  --is-supplier: oneof<nothing, bool>
  --is-prospect: oneof<nothing, bool>
  --importance-level: int
  --rating: int
  --balance-initial-amount: int
  --is-notifying: oneof<nothing, bool>
  --note: string
  --reference: string # Accounting number if it's specific (nullable)
  --tags: string # nullable
  --discount: string # nullable
  --details: string # nullable
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/relationships/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: is_customer, var: is_customer}, {name: is_supplier, var: is_supplier}, {name: is_prospect, var: is_prospect}, {name: importance_level, var: importance_level}, {name: rating, var: rating}, {name: balance_initial_amount, var: balance_initial_amount}, {name: is_notifying, var: is_notifying}, {name: note, var: note}, {name: reference, var: reference}, {name: tags, var: tags}, {name: discount, var: discount}, {name: details, var: details}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, is_customer: $is_customer, is_supplier: $is_supplier, is_prospect: $is_prospect, importance_level: $importance_level, rating: $rating, balance_initial_amount: $balance_initial_amount, is_notifying: $is_notifying, note: $note, reference: $reference, tags: $tags, discount: $discount, details: $details, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file
#
# DELETE /apps/{appId}/relationships/{id}/attach
# operationId: app.contacts.relationships.detach
export def "app-contacts-relationships-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/relationships/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file
#
# POST /apps/{appId}/relationships/{id}/attach
# operationId: app.contacts.relationships.attach
export def "app-contacts-relationships-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/relationships/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset all data
#
# POST /apps/{appId}/reset
# operationId: app.reset
export def "app-reset" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/reset"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /apps/{appId}/rules/
# Returns: table<conditions: list<list>, id: int, on_event: string, parameter: string, priority: int, value: string>
# operationId: app.rules.list
export def "app-rules-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/rules/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a rule
#
# POST /apps/{appId}/rules/
# Returns: record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>
# operationId: app.rules.create
export def "app-rules-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: list
  --on-event: string # Event like model.event, event in [saved, created, updated, deleted] (e.g. transaction.created)
  --parameter: string # e.g. account
  --value: string # e.g. 64
  --priority: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/rules/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: conditions, var: conditions, style: multi}, {name: on_event, var: on_event}, {name: parameter, var: parameter}, {name: value, var: value}, {name: priority, var: priority}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, conditions: $conditions, on_event: $on_event, parameter: $parameter, value: $value, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute all rules
#
# POST /apps/{appId}/rules/execute_on
# Returns: record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>
# operationId: app.rules.execute_on
export def "app-rules-execute-on" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # e.g. transaction
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/rules/execute_on"
    path_params: [{name: appId, var: app_id}]
    query: [{name: model, var: model}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, model: $model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a rule
#
# DELETE /apps/{appId}/rules/{id}
# operationId: app.rules.delete
export def "app-rules-delete" [
  app_id: int
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
    path: "/apps/{appId}/rules/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule
#
# GET /apps/{appId}/rules/{id}
# Returns: record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>
# operationId: app.rules.get
export def "app-rules-get" [
  app_id: int
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
    path: "/apps/{appId}/rules/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a rule
#
# POST /apps/{appId}/rules/{id}
# Returns: record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string>
# operationId: app.rules.update
export def "app-rules-update" [
  app_id: int
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
  --conditions: list
  --on-event: string # e.g. transaction.creating
  --parameter: string # e.g. account
  --value: string # e.g. 64
  --priority: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/rules/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: conditions, var: conditions, style: multi}, {name: on_event, var: on_event}, {name: parameter, var: parameter}, {name: value, var: value}, {name: priority, var: priority}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, conditions: $conditions, on_event: $on_event, parameter: $parameter, value: $value, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List sales documents models
#
# GET /apps/{appId}/salesdocumentmodels
# Returns: table<id: int, json: list<record>, name: string, title: string>
# operationId: app.documents.sales.models.list
export def "app-documents-sales-models-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/salesdocumentmodels"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a sales document model
#
# POST /apps/{appId}/salesdocumentmodels
# Returns: record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>
# operationId: app.documents.sales.models.create
export def "app-documents-sales-models-create" [
  app_id: int
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
  --title: string
  --content: list
  --columns: record # List columns to display
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/salesdocumentmodels"
    path_params: [{name: appId, var: app_id}]
    query: [{name: name, var: name}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, name: $name, title: $title, content: $content, columns: $columns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a sales document model
#
# DELETE /apps/{appId}/salesdocumentmodels/{id}
# operationId: app.documents.sales.models.delete
export def "app-documents-sales-models-delete" [
  app_id: int
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
    path: "/apps/{appId}/salesdocumentmodels/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a sales document model
#
# GET /apps/{appId}/salesdocumentmodels/{id}
# Returns: record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>
# operationId: app.documents.sales.models.get
export def "app-documents-sales-models-get" [
  app_id: int
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
    path: "/apps/{appId}/salesdocumentmodels/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a sales document model
#
# POST /apps/{appId}/salesdocumentmodels/{id}
# Returns: record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string>
# operationId: app.documents.sales.models.update
export def "app-documents-sales-models-update" [
  app_id: int
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
  --name: string
  --title: string
  --content: list
  --columns: record # List columns to display
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/salesdocumentmodels/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: name, var: name}, {name: title, var: title}, {name: content, var: content, style: multi}, {name: columns, var: columns, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, name: $name, title: $title, content: $content, columns: $columns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List SEPAMandate
#
# GET /apps/{appId}/sepamandates/
# Returns: table<author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>
# operationId: app.payments.sepamandates.list
export def "app-payments-sepamandates-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/sepamandates/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a SEPAMandate
#
# POST /apps/{appId}/sepamandates/
# Returns: record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>
# operationId: app.payments.sepamandates.create
export def "app-payments-sepamandates-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-organization-id: int
  --customer-person-id: int
  --old-mandate-id: int
  --mandate-id: string # required
  --signed-at: string # required, format: date-time
  --electronic-signature: string
  --customer-name: string
  --iban: string # required
  --bic: string # required
  --is-first: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/sepamandates/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: customer_organization_id, var: customer_organization_id}, {name: customer_person_id, var: customer_person_id}, {name: old_mandate_id, var: old_mandate_id}, {name: mandate_id, var: mandate_id, required: true}, {name: signed_at, var: signed_at, required: true}, {name: electronic_signature, var: electronic_signature}, {name: customer_name, var: customer_name}, {name: iban, var: iban, required: true}, {name: bic, var: bic, required: true}, {name: is_first, var: is_first}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, customer_organization_id: $customer_organization_id, customer_person_id: $customer_person_id, old_mandate_id: $old_mandate_id, mandate_id: $mandate_id, signed_at: $signed_at, electronic_signature: $electronic_signature, customer_name: $customer_name, iban: $iban, bic: $bic, is_first: $is_first
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview sepa credit transfer file
#
# GET /apps/{appId}/sepamandates/credittransfer
# Returns: record
# operationId: app.payments.sepacredittransfer.preview
export def "app-payments-sepacredittransfer-preview" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/sepamandates/credittransfer"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview sepa credit transfer file
#
# POST /apps/{appId}/sepamandates/credittransfer
# operationId: app.payments.sepacredittransfer.download
export def "app-payments-sepacredittransfer-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # required
  --amounts: list<int> # Optional array with amounts (keys must to correspond to ids)
  --debtor-name: string
  --debtor-iban: string
  --debtor-bic: string
  --btch-bookg: int
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/sepamandates/credittransfer"
    path_params: [{name: appId, var: app_id}]
    query: [{name: ids, var: ids, style: multi, required: true}, {name: amounts, var: amounts, style: multi}, {name: debtor_name, var: debtor_name}, {name: debtor_iban, var: debtor_iban}, {name: debtor_bic, var: debtor_bic}, {name: btchBookg, var: btch_bookg}]
    accept: ["application/xml"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, ids: $ids, amounts: $amounts, debtor_name: $debtor_name, debtor_iban: $debtor_iban, debtor_bic: $debtor_bic, btch_bookg: $btch_bookg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview sepa direct debit file
#
# GET /apps/{appId}/sepamandates/directdebit
# Returns: record
# operationId: app.payments.sepadirectdebit.preview
export def "app-payments-sepadirectdebit-preview" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int> # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/sepamandates/directdebit"
    path_params: [{name: appId, var: app_id}]
    query: [{name: invoices_ids, var: invoices_ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, invoices_ids: $invoices_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download sepa direct debit file
#
# POST /apps/{appId}/sepamandates/directdebit
# operationId: app.payments.sepadirectdebit.download
export def "app-payments-sepadirectdebit-download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int> # required
  --amounts: list<int> # Optional array with amounts (keys must to correspond to invoices_ids)
  --creditor-name: string
  --creditor-iban: string
  --creditor-bic: string
  --creditor-ics: string
  --date: string # format: date-time
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/sepamandates/directdebit"
    path_params: [{name: appId, var: app_id}]
    query: [{name: invoices_ids, var: invoices_ids, style: multi, required: true}, {name: amounts, var: amounts, style: multi}, {name: creditor_name, var: creditor_name}, {name: creditor_iban, var: creditor_iban}, {name: creditor_bic, var: creditor_bic}, {name: creditor_ics, var: creditor_ics}, {name: date, var: date}]
    accept: ["application/xml"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, invoices_ids: $invoices_ids, amounts: $amounts, creditor_name: $creditor_name, creditor_iban: $creditor_iban, creditor_bic: $creditor_bic, creditor_ics: $creditor_ics, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a SEPAMandate
#
# DELETE /apps/{appId}/sepamandates/{id}
# operationId: app.payments.sepamandates.delete
export def "app-payments-sepamandates-delete" [
  app_id: int
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
    path: "/apps/{appId}/sepamandates/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a SEPAMandate
#
# GET /apps/{appId}/sepamandates/{id}
# Returns: record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>
# operationId: app.payments.sepamandates.get
export def "app-payments-sepamandates-get" [
  app_id: int
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
    path: "/apps/{appId}/sepamandates/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SEPAMandate
#
# POST /apps/{appId}/sepamandates/{id}
# Returns: record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string>
# operationId: app.payments.sepamandates.update
export def "app-payments-sepamandates-update" [
  app_id: int
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
  --customer-organization-id: int
  --customer-person-id: int
  --old-mandate-id: int
  --mandate-id: string
  --signed-at: string # format: date-time
  --electronic-signature: string
  --customer-name: string
  --iban: string
  --bic: string
  --is-first: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/sepamandates/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: customer_organization_id, var: customer_organization_id}, {name: customer_person_id, var: customer_person_id}, {name: old_mandate_id, var: old_mandate_id}, {name: mandate_id, var: mandate_id}, {name: signed_at, var: signed_at}, {name: electronic_signature, var: electronic_signature}, {name: customer_name, var: customer_name}, {name: iban, var: iban}, {name: bic, var: bic}, {name: is_first, var: is_first}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, customer_organization_id: $customer_organization_id, customer_person_id: $customer_person_id, old_mandate_id: $old_mandate_id, mandate_id: $mandate_id, signed_at: $signed_at, electronic_signature: $electronic_signature, customer_name: $customer_name, iban: $iban, bic: $bic, is_first: $is_first
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping Stripe webhook endpoint
#
# GET /apps/{appId}/services/stripe/webhook
# operationId: app.services.stripe.webhook.ping
export def "app-services-stripe-webhook-ping" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/services/stripe/webhook"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Webhook for Stripe
#
# POST /apps/{appId}/services/stripe/webhook
# operationId: app.services.stripe.webhook.handle
export def "app-services-stripe-webhook-handle" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/services/stripe/webhook"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Webhook for Yousign
#
# POST /apps/{appId}/services/yousign/webhook
# operationId: app.services.yousign.webhook.handle
export def "app-services-yousign-webhook-handle" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/services/yousign/webhook"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get app config
#
# GET /apps/{appId}/settings
# Returns: record
# operationId: app.settings.get
export def "app-settings-get" [
  app_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/settings"
    path_params: [{name: appId, var: app_id}]
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update app config
#
# POST /apps/{appId}/settings
# Returns: record<code: int, message: string, type: string>
# operationId: app.settings.update
export def "app-settings-update" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # e.g. {accounting.export.journals.VE: VE, accounting.template.color-primary: #003B51}
  --key: string
  --value: string # Value can be a primitive or a file
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/settings"
    path_params: [{name: appId, var: app_id}]
    query: [{name: settings, var: settings, style: multi}, {name: key, var: key}, {name: value, var: value}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, settings: $settings, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a signature
#
# POST /apps/{appId}/signature
# operationId: app.documents.sales.signature.create
export def "app-documents-sales-signature-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: int # required
  --email: string # required
  --firstname: string # required
  --lastname: string # required
  --phone: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/signature"
    path_params: [{name: appId, var: app_id}]
    query: [{name: documentId, var: document_id, required: true}, {name: email, var: email, required: true}, {name: firstname, var: firstname, required: true}, {name: lastname, var: lastname, required: true}, {name: phone, var: phone, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, document_id: $document_id, email: $email, firstname: $firstname, lastname: $lastname, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about sales
#
# GET /apps/{appId}/statistics/charts/{type}
# Returns: list<record>
# operationId: app.statistics.charts.get
export def "app-statistics-charts-get" [
  app_id: int
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
  --count: int
  --period: string@period-completer
  --start-at: string # format: date-time
  --object: string@object-completer
  --object-property: string
  --calcul: string@calcul-completer
  --methods: list # Array of [object_property, calcul]
  --object-date-property: string
  --group-by: list<string>
  --group-by-object-name: string
  --exclude-keys: list<int>
  --search: string
  --filters: record
  --show-details: oneof<nothing, bool> # Recovers the details of the calculations
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/statistics/charts/{type}"
    path_params: [{name: appId, var: app_id}, {name: type, var: type}]
    query: [{name: count, var: count}, {name: period, var: period}, {name: start_at, var: start_at}, {name: object, var: object}, {name: object_property, var: object_property}, {name: calcul, var: calcul}, {name: methods, var: methods, style: multi}, {name: object_date_property, var: object_date_property}, {name: group_by, var: group_by, style: multi}, {name: group_by_object_name, var: group_by_object_name}, {name: exclude_keys, var: exclude_keys, style: multi}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: show_details, var: show_details}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, type: $type, count: $count, period: $period, start_at: $start_at, object: $object, object_property: $object_property, calcul: $calcul, methods: $methods, object_date_property: $object_date_property, group_by: $group_by, group_by_object_name: $group_by_object_name, exclude_keys: $exclude_keys, search: $search, filters: $filters, show_details: $show_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about timetable purchases
#
# GET /apps/{appId}/statistics/timetable/purchases
# Returns: table<balance: int, count: int, data: list<record>, interval: list<string>>
# operationId: app.statistics.timetable.purchases
export def "app-statistics-timetable-purchases" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --groups: list # default: [ [-730, -30], [-30, -1], [-1, 7], [7, 15], [15, 30], [30, 730] ]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/statistics/timetable/purchases"
    path_params: [{name: appId, var: app_id}]
    query: [{name: detailed, var: detailed}, {name: groups, var: groups, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, detailed: $detailed, groups: $groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about sales
#
# GET /apps/{appId}/statistics/timetable/sales
# Returns: table<balance: int, count: int, data: list<record>, interval: list<string>>
# operationId: app.statistics.timetable.sales
export def "app-statistics-timetable-sales" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --groups: list # default: [ [-730, -30], [-30, -1], [-1, 7], [7, 15], [15, 30], [30, 730] ]
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/statistics/timetable/sales"
    path_params: [{name: appId, var: app_id}]
    query: [{name: detailed, var: detailed}, {name: groups, var: groups, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, detailed: $detailed, groups: $groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Obtain statistics about vat
#
# GET /apps/{appId}/statistics/vat
# Returns: record
# operationId: app.statistics.vat.get
export def "app-statistics-vat-get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --start-at: string # format: date-time, default: now
  --period: string@period-completer-1
  --end-at: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/statistics/vat"
    path_params: [{name: appId, var: app_id}]
    query: [{name: detailed, var: detailed}, {name: start_at, var: start_at}, {name: period, var: period}, {name: end_at, var: end_at}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, detailed: $detailed, start_at: $start_at, period: $period, end_at: $end_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update anchor date
#
# POST /apps/{appId}/subscription/anchordate
# operationId: app.subscription.anchordate
export def "app-subscription-anchordate" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/anchordate"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment link to Stripe Checkout
#
# GET /apps/{appId}/subscription/checkout_add_source
# operationId: app.subscription.checkout_add_source
export def "app-subscription-checkout-add-source" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/checkout_add_source"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add coupon
#
# POST /apps/{appId}/subscription/coupon
# operationId: app.subscription.coupon
export def "app-subscription-coupon" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/subscription/coupon"
    path_params: [{name: appId, var: app_id}]
    query: [{name: code, var: code, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extend trial period
#
# POST /apps/{appId}/subscription/extend_trial
# operationId: app.subscription.extend_trial
export def "app-subscription-extend-trial" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/extend_trial"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable plan
#
# POST /apps/{appId}/subscription/extra/{stripe_plan}
# operationId: app.subscription.extra_enable
export def "app-subscription-extra-enable" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/extra/{stripe_plan}"
    path_params: [{name: appId, var: app_id}, {name: stripe_plan, var: stripe_plan}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_plan: $stripe_plan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pay all due invoices
#
# POST /apps/{appId}/subscription/pay_all
# operationId: app.subscription.pay_all
export def "app-subscription-pay-all" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/pay_all"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# End current plan
#
# DELETE /apps/{appId}/subscription/plan
# operationId: app.subscription.end
export def "app-subscription-end" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/subscription/plan"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current plan
#
# GET /apps/{appId}/subscription/plan
# Returns: record<extras: list<string>, plans: list<string>>
# operationId: app.subscription.get
export def "app-subscription-get" [
  app_id: int
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
    path: "/apps/{appId}/subscription/plan"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get plans
#
# GET /apps/{appId}/subscription/plans
# Returns: record<extras: list<string>, plans: list<string>>
# operationId: app.subscription.list
export def "app-subscription-list" [
  app_id: int
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
    path: "/apps/{appId}/subscription/plans"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate a plan
#
# GET /apps/{appId}/subscription/plans/{stripe_plan}
# operationId: app.subscription.upcoming
export def "app-subscription-upcoming" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-coupon: string # Stripe coupon id to simulate invoice (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/subscription/plans/{stripe_plan}"
    path_params: [{name: appId, var: app_id}, {name: stripe_plan, var: stripe_plan}]
    query: [{name: stripe_coupon, var: stripe_coupon}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_plan: $stripe_plan, stripe_coupon: $stripe_coupon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change plan
#
# POST /apps/{appId}/subscription/plans/{stripe_plan}
# operationId: app.subscription.pay
export def "app-subscription-pay" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay (nullable)
  --stripe-coupon: string # Stripe coupon id to apply (nullable)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/subscription/plans/{stripe_plan}"
    path_params: [{name: appId, var: app_id}, {name: stripe_plan, var: stripe_plan}]
    query: [{name: stripe_source, var: stripe_source}, {name: stripe_coupon, var: stripe_coupon}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_plan: $stripe_plan, stripe_source: $stripe_source, stripe_coupon: $stripe_coupon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get payment link to Stripe Checkout
#
# GET /apps/{appId}/subscription/plans/{stripe_plan}/checkout
# operationId: app.subscription.checkout
export def "app-subscription-checkout" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-coupon: string # Stripe coupon id to simulate invoice (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/apps/{appId}/subscription/plans/{stripe_plan}/checkout"
    path_params: [{name: appId, var: app_id}, {name: stripe_plan, var: stripe_plan}]
    query: [{name: stripe_coupon, var: stripe_coupon}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_plan: $stripe_plan, stripe_coupon: $stripe_coupon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove creditcard or sepadebit
#
# DELETE /apps/{appId}/subscription/source
# operationId: app.subscription.remove_source
export def "app-subscription-remove-source" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/subscription/source"
    path_params: [{name: appId, var: app_id}]
    query: [{name: stripe_source, var: stripe_source, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_source: $stripe_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add creditcard or sepadebit
#
# POST /apps/{appId}/subscription/source
# operationId: app.subscription.add_source
export def "app-subscription-add-source" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/subscription/source"
    path_params: [{name: appId, var: app_id}]
    query: [{name: stripe_source, var: stripe_source, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_source: $stripe_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change default source
#
# POST /apps/{appId}/subscription/source/default
# operationId: app.subscription.set_default
export def "app-subscription-set-default" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to set as default source (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/subscription/source/default"
    path_params: [{name: appId, var: app_id}]
    query: [{name: stripe_source, var: stripe_source, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_id: $app_id, stripe_source: $stripe_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all existants tags
#
# GET /apps/{appId}/tags
# Returns: list<record>
# operationId: app.statistics.tags.get
export def "app-statistics-tags-get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object: string@object-completer-1
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/tags"
    path_params: [{name: appId, var: app_id}]
    query: [{name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get templates
#
# GET /apps/{appId}/templates
# operationId: app.settings.templates.list
export def "app-settings-templates-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/templates"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a template
#
# POST /apps/{appId}/templates
# operationId: app.settings.templates.create
export def "app-settings-templates-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/templates"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple templates
#
# POST /apps/{appId}/templates/batch
# operationId: app.settings.templates.batch
export def "app-settings-templates-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of templates. With ID for update, without for insert (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/templates/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get default template
#
# GET /apps/{appId}/templates/default
# operationId: app.settings.templates.default_template
export def "app-settings-templates-default-template" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/templates/default"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a template
#
# GET /apps/{appId}/templates/{id}
# operationId: app.settings.templates.get
export def "app-settings-templates-get" [
  app_id: int
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
    method: get
    path: "/apps/{appId}/templates/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a template
#
# POST /apps/{appId}/templates/{id}
# operationId: app.settings.templates.update
export def "app-settings-templates-update" [
  app_id: int
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
    method: post
    path: "/apps/{appId}/templates/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Transaction
#
# GET /apps/{appId}/transactions/
# Returns: table<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>
# operationId: app.cashflow.transactions.list
export def "app-cashflow-transactions-list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/transactions/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: search, var: search}, {name: filters, var: filters, style: multi}, {name: order, var: order, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, offset: $offset, limit: $limit, search: $search, filters: $filters, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Transaction
#
# POST /apps/{appId}/transactions/
# Returns: record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>
# operationId: app.cashflow.transactions.create
export def "app-cashflow-transactions-create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-organization-id: int
  --contact-person-id: int
  --account-id: int
  --cashflow-source-id: int # required
  --contact-name: string
  --amount: int # required
  --method: string@method-completer
  --received-at: string # required, format: date-time
  --label: string
  --details: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/transactions/"
    path_params: [{name: appId, var: app_id}]
    query: [{name: contact_organization_id, var: contact_organization_id}, {name: contact_person_id, var: contact_person_id}, {name: account_id, var: account_id}, {name: cashflow_source_id, var: cashflow_source_id, required: true}, {name: contact_name, var: contact_name}, {name: amount, var: amount, required: true}, {name: method, var: method}, {name: received_at, var: received_at, required: true}, {name: label, var: label}, {name: details, var: details}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, contact_organization_id: $contact_organization_id, contact_person_id: $contact_person_id, account_id: $account_id, cashflow_source_id: $cashflow_source_id, contact_name: $contact_name, amount: $amount, method: $method, received_at: $received_at, label: $label, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create multiple transactions
#
# POST /apps/{appId}/transactions/batch
# Returns: record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>
# operationId: app.cashflow.transactions.batch
export def "app-cashflow-transactions-batch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of transactions. With ID for update, without for insert (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/transactions/batch"
    path_params: [{name: appId, var: app_id}]
    query: [{name: data, var: data, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Transaction
#
# DELETE /apps/{appId}/transactions/{id}
# operationId: app.cashflow.transactions.delete
export def "app-cashflow-transactions-delete" [
  app_id: int
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
    path: "/apps/{appId}/transactions/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Transaction
#
# GET /apps/{appId}/transactions/{id}
# Returns: record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>
# operationId: app.cashflow.transactions.get
export def "app-cashflow-transactions-get" [
  app_id: int
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
    path: "/apps/{appId}/transactions/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Transaction
#
# POST /apps/{appId}/transactions/{id}
# Returns: record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>
# operationId: app.cashflow.transactions.update
export def "app-cashflow-transactions-update" [
  app_id: int
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
  --contact-organization-id: int
  --contact-person-id: int
  --account-id: int
  --cashflow-source-id: int
  --contact-name: string
  --amount: int
  --method: string@method-completer
  --received-at: string # format: date-time
  --label: string
  --details: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/{appId}/transactions/{id}"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: contact_organization_id, var: contact_organization_id}, {name: contact_person_id, var: contact_person_id}, {name: account_id, var: account_id}, {name: cashflow_source_id, var: cashflow_source_id}, {name: contact_name, var: contact_name}, {name: amount, var: amount}, {name: method, var: method}, {name: received_at, var: received_at}, {name: label, var: label}, {name: details, var: details}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, contact_organization_id: $contact_organization_id, contact_person_id: $contact_person_id, account_id: $account_id, cashflow_source_id: $cashflow_source_id, contact_name: $contact_name, amount: $amount, method: $method, received_at: $received_at, label: $label, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a file
#
# DELETE /apps/{appId}/transactions/{id}/attach
# operationId: app.cashflow.transactions.detach
export def "app-cashflow-transactions-detach" [
  app_id: int
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
  --file-id: int # File to detach
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{appId}/transactions/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a file
#
# POST /apps/{appId}/transactions/{id}/attach
# operationId: app.cashflow.transactions.attach
export def "app-cashflow-transactions-attach" [
  app_id: int
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
  --file: string # File to attach (format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/transactions/{id}/attach"
    path_params: [{name: appId, var: app_id}, {name: id, var: id}]
    query: [{name: file, var: file}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login URSSAF
#
# POST /apps/{appId}/urssaf/auth
# operationId: app.payments.urssaftiers.auth
export def "app-payments-urssaftiers-auth" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # required
  --client-secret: string # required
]: nothing -> any {
  http-request {
    method: post
    path: "/apps/{appId}/urssaf/auth"
    path_params: [{name: appId, var: app_id}]
    query: [{name: client_id, var: client_id, required: true}, {name: client_secret, var: client_secret, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status of a payment
#
# GET /apps/{appId}/urssaf/payment
# Returns: record
# operationId: app.payments.urssaftiers.get_status
export def "app-payments-urssaftiers-get-status" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int> # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/urssaf/payment"
    path_params: [{name: appId, var: app_id}]
    query: [{name: invoices_ids, var: invoices_ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, invoices_ids: $invoices_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send URSSAF request payment
#
# POST /apps/{appId}/urssaf/payment
# operationId: app.payments.urssaftiers.send_payments
export def "app-payments-urssaftiers-send-payments" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/urssaf/payment"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/xml"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Preview URSSAF request payment
#
# GET /apps/{appId}/urssaf/preview
# Returns: record
# operationId: app.payments.urssaftiers.preview
export def "app-payments-urssaftiers-preview" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-5 # required
  --ids: list<int> # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{appId}/urssaf/preview"
    path_params: [{name: appId, var: app_id}]
    query: [{name: type, var: type, required: true}, {name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id, type: $type, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a person to URSSAF and create him a mandate
#
# POST /apps/{appId}/urssaf/register_customer
# operationId: app.payments.urssaftiers.register_customer
export def "app-payments-urssaftiers-register-customer" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/apps/{appId}/urssaf/register_customer"
    path_params: [{name: appId, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password
#
# POST /changepassword
# operationId: auth.changepassword
export def "auth-changepassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --forgotten-password-token: string # required
  --password: string # Password for account (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/changepassword"
    query: [{name: forgotten_password_token, var: forgotten_password_token, required: true}, {name: password, var: password, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    forgotten_password_token: $forgotten_password_token, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login
#
# POST /login
# operationId: auth.login
export def "auth-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for login (required, format: email)
  --password: string # Password for login in clear text (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/login"
    query: [{name: email, var: email, required: true}, {name: password, var: password, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout
#
# POST /logout
# operationId: auth.logout
export def "auth-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/logout"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current user
#
# GET /me
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>
# operationId: account.get
export def "account-get" [
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current user
#
# POST /me
# Returns: record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>
# operationId: account.update
export def "account-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --civility: string
  --firstname: string
  --lastname: string
  --password: string
  --email: string # format: email
  --image: string # format: binary
  --metadata: list # nullable
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/me"
    query: [{name: civility, var: civility}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: password, var: password}, {name: email, var: email}, {name: image, var: image}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    civility: $civility, firstname: $firstname, lastname: $lastname, password: $password, email: $email, image: $image, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping server
#
# GET /ping
# operationId: auth.ping
export def "auth-ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/ping"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh a token
#
# GET /refresh
# Returns: record<access_token: string, expires_in: int, token_type: string>
# operationId: auth.refresh
export def "auth-refresh" [
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
    path: "/refresh"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an User
#
# POST /register
# operationId: account.create
export def "account-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email is the user's login, it must not have been registered (required, format: email)
  --password: string # required
  --cgu: oneof<nothing, bool> # The user must have validated the T&Cs (required)
  --firstname: string
  --lastname: string
  --metadata: list # nullable
]: nothing -> any {
  http-request {
    method: post
    path: "/register"
    query: [{name: email, var: email, required: true}, {name: password, var: password, required: true}, {name: cgu, var: cgu, required: true}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: metadata, var: metadata, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email, password: $password, cgu: $cgu, firstname: $firstname, lastname: $lastname, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Password recover by email
#
# POST /sendpassword
# operationId: auth.sendpassword
export def "auth-sendpassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for login (required, format: email)
]: nothing -> any {
  http-request {
    method: post
    path: "/sendpassword"
    query: [{name: email, var: email, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push to purchase collector
#
# POST /services/collector
# operationId: admin.purchaseCollector.push
export def "admin-purchase-collector-push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-identifiant: string # required
  --collector-key: string # required
  --invoice: string # Invoice or receipt file (pdf or image) (required, format: binary)
]: nothing -> any {
  http-request {
    method: post
    path: "/services/collector"
    query: [{name: app_identifiant, var: app_identifiant, required: true}, {name: collector_key, var: collector_key, required: true}, {name: invoice, var: invoice, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    app_identifiant: $app_identifiant, collector_key: $collector_key, invoice: $invoice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get VIES database informations from SIREN
#
# GET /services/vies/{siren}
# operationId: services.vies.get
export def "services-vies-get" [
  siren: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/services/vies/{siren}"
    path_params: [{name: siren, var: siren}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    siren: $siren
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
