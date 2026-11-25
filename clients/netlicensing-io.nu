# Auto-generated client for Labs64 NetLicensing RESTful API Test Center v2.x
# Source: https://api.apis.guru/v2/specs/netlicensing.io/2.x/openapi.json
# Auth: --token flag or $env.LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN

const CLIENT = {
  base_url: "https://go.netlicensing.io/core/v2/rest"
  token_env_var: "LABS64_NETLICENSING_RESTFUL_API_TEST_CENTER_TOKEN"
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

def base-url-completer [] { ["https://go.netlicensing.io/core/v2/rest"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def action-completer [] { ["checkIn" "checkOut"] }
def vat-mode-completer [] { ["GROSS" "NET"] }
def action-completer-1 [] { ["licenseeLogin"] }
def api-key-role-completer [] { ["ROLE_APIKEY_ADMIN" "ROLE_APIKEY_ANALYTICS" "ROLE_APIKEY_LICENSEE" "ROLE_APIKEY_MAINTENANCE" "ROLE_APIKEY_OPERATION"] }
def token-type-completer [] { ["APIKEY" "DEFAULT" "SHOP"] }
def type-completer [] { ["ACTION"] }
def source-completer [] { ["SHOP"] }
def status-completer [] { ["CANCELLED" "CLOSED" "PENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-licenses: "table<infos: any, items: any>"
    create-license: "record<infos: any, items: any>"
    delete-license: "record<infos: any, items: any>"
    get-license: "record<infos: any, items: any>"
    update-license: "record<infos: any, items: any>"
    list-licensees: "table<infos: any, items: any>"
    create-licensee: "record<infos: any, items: any>"
    delete-licensee: "record<infos: any, items: any>"
    get-licensee: "record<infos: any, items: any>"
    update-licensee: "record<infos: any, items: any>"
    transfer-licenses: "record<infos: any, items: any>"
    validate-licensee: "record<infos: any, items: any>"
    list-license-templates: "table<infos: any, items: any>"
    create-license-template: "record<infos: any, items: any>"
    delete-license-template: "record<infos: any, items: any>"
    get-license-template: "record<infos: any, items: any>"
    update-license-template: "record<infos: any, items: any>"
    list-payment-methods: "table<infos: any, items: any>"
    get-payment-method: "record<infos: any, items: any>"
    update-payment-method: "record<infos: any, items: any>"
    list-products: "table<infos: any, items: any>"
    create-product: "record<infos: any, items: any>"
    delete-product: "record<infos: any, items: any>"
    product-number: "record<infos: any, items: any>"
    update-product: "record<infos: any, items: any>"
    list-product-modules: "table<infos: any, items: any>"
    create-product-module: "record<infos: any, items: any>"
    delete-product-module: "record<infos: any, items: any>"
    get-product-module: "record<infos: any, items: any>"
    update-product-module: "record<infos: any, items: any>"
    list-tokens: "table<infos: any, items: any>"
    create-token: "record<infos: any, items: any>"
    delete-token: "record<infos: any, items: any>"
    get-token: "record<infos: any, items: any>"
    list-transactions: "table<infos: any, items: any>"
    create-transaction: "record<infos: any, items: any>"
    get-transaction: "record<infos: any, items: any>"
    update-transaction: "record<infos: any, items: any>"
    license-types: "record<infos: any, items: any>"
    licensing-models: "record<infos: any, items: any>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-licenses" "create-license" "delete-license" "get-license" "update-license" "list-licensees" "create-licensee" "delete-licensee" "get-licensee" "update-licensee" "transfer-licenses" "validate-licensee" "list-license-templates" "create-license-template" "delete-license-template" "get-license-template" "update-license-template" "list-payment-methods" "get-payment-method" "update-payment-method" "list-products" "create-product" "delete-product" "product-number" "update-product" "list-product-modules" "create-product-module" "delete-product-module" "get-product-module" "update-product-module" "list-tokens" "create-token" "delete-token" "get-token" "list-transactions" "create-transaction" "get-transaction" "update-transaction" "license-types" "licensing-models" "commands"] | sort) } | get name | first)
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

# List Licenses
#
# GET /license
# Returns: table<infos: any, items: any>
# operationId: listLicenses
export def "list-licenses" [
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
    path: "/license"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create License
#
# POST /license
# Returns: record<infos: any, items: any>
# operationId: createLicense
export def "create-license" [
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
  --active: oneof<nothing, bool>
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported. Read-only, set from License Template on creation
  --hidden: oneof<nothing, bool> # If set to 'true', this License is not shown in NetLicensing Shop as purchased License. Set from License Template on creation, if not specified explicitly
  license_template_number: string
  licensee_number: string
  --name: string # Name for the Licensed item. Set from License Template on creation, if not specified explicitly.
  --number: string
  --parentfeature: string # Mandatory for 'TIMEVOLUME' License Type and 'RENTAL' licensing model
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. Read-only, set from License Template on creation (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' License Model.
  --start-date: string # Mandatory for 'TIMEVOLUME' License Type. (format: date-time)
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
  --used-quantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/license"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: currency, var: currency}, {name: hidden, var: hidden}, {name: licenseTemplateNumber, var: license_template_number}, {name: licenseeNumber, var: licensee_number}, {name: name, var: name}, {name: number, var: number}, {name: parentfeature, var: parentfeature}, {name: price, var: price}, {name: quantity, var: quantity}, {name: startDate, var: start_date}, {name: timeVolume, var: time_volume}, {name: timeVolumePeriod, var: time_volume_period}, {name: usedQuantity, var: used_quantity}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, currency: $currency, hidden: $hidden, license_template_number: $license_template_number, licensee_number: $licensee_number, name: $name, number: $number, parentfeature: $parentfeature, price: $price, quantity: $quantity, start_date: $start_date, time_volume: $time_volume, time_volume_period: $time_volume_period, used_quantity: $used_quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete License
#
# DELETE /license/{licenseNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteLicense
export def "delete-license" [
  license_number: string
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
    method: delete
    path: "/license/{licenseNumber}"
    path_params: [{name: licenseNumber, var: license_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_number: $license_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get License
#
# GET /license/{licenseNumber}
# Returns: record<infos: any, items: any>
# operationId: getLicense
export def "get-license" [
  license_number: string
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
    path: "/license/{licenseNumber}"
    path_params: [{name: licenseNumber, var: license_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_number: $license_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update License
#
# POST /license/{licenseNumber}
# Returns: record<infos: any, items: any>
# operationId: updateLicense
export def "update-license" [
  license_number: string
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
  --active: oneof<nothing, bool>
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported. Read-only, set from License Template on creation
  --hidden: oneof<nothing, bool> # If set to 'true', this License is not shown in NetLicensing Shop as purchased License. Set from License Template on creation, if not specified explicitly
  --name: string # Name for the Licensed item. Set from License Template on creation, if not specified explicitly.
  --number: string # Unique number (across all Products/Licensees of a Vendor) that identifies the License. Vendor can assign this number when creating a License or let NetLicensing generate one. Read-only after corresponding creation Transaction status is set to closed.
  --parentfeature: string
  --price: float # Price for the License. If > 0, it must always be accompanied by the currency specification. Read-only, set from License Template on creation (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' License Model.
  --start-date: string # For 'TIMEVOLUME' License type (format: date-time)
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
  --used-quantity: string # Mandatory for 'Pay-per-Use' License Model.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/license/{licenseNumber}"
    path_params: [{name: licenseNumber, var: license_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: currency, var: currency}, {name: hidden, var: hidden}, {name: name, var: name}, {name: number, var: number}, {name: parentfeature, var: parentfeature}, {name: price, var: price}, {name: quantity, var: quantity}, {name: startDate, var: start_date}, {name: timeVolume, var: time_volume}, {name: timeVolumePeriod, var: time_volume_period}, {name: usedQuantity, var: used_quantity}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_number: $license_number, active: $active, currency: $currency, hidden: $hidden, name: $name, number: $number, parentfeature: $parentfeature, price: $price, quantity: $quantity, start_date: $start_date, time_volume: $time_volume, time_volume_period: $time_volume_period, used_quantity: $used_quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Licensees
#
# GET /licensee
# Returns: table<infos: any, items: any>
# operationId: listLicensees
export def "list-licensees" [
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
    path: "/licensee"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Licensee
#
# POST /licensee
# Returns: record<infos: any, items: any>
# operationId: createLicensee
export def "create-licensee" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --marked-for-transfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Licensee. Vendor can assign this number when creating a Licensee or let NetLicensing generate one. Read-only after creation of the first License for the Licensee
  product_number: string # 'productNumber' to assign new Licensee object
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensee"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: markedForTransfer, var: marked_for_transfer}, {name: name, var: name}, {name: number, var: number}, {name: productNumber, var: product_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, marked_for_transfer: $marked_for_transfer, name: $name, number: $number, product_number: $product_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Licensee
#
# DELETE /licensee/{licenseeNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteLicensee
export def "delete-licensee" [
  licensee_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/licensee/{licenseeNumber}"
    path_params: [{name: licenseeNumber, var: licensee_number}]
    query: [{name: forceCascade, var: force_cascade}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    licensee_number: $licensee_number, force_cascade: $force_cascade
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Licensee
#
# GET /licensee/{licenseeNumber}
# Returns: record<infos: any, items: any>
# operationId: getLicensee
export def "get-licensee" [
  licensee_number: string
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
    path: "/licensee/{licenseeNumber}"
    path_params: [{name: licenseeNumber, var: licensee_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    licensee_number: $licensee_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Licensee
#
# POST /licensee/{licenseeNumber}
# Returns: record<infos: any, items: any>
# operationId: updateLicensee
export def "update-licensee" [
  licensee_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Licensee is disabled. Licensee can not obtain new Licenses, and validation is disabled
  --marked-for-transfer: oneof<nothing, bool> # Mark Licensee for transfer.
  --name: string
  --number: string # New Licensee number (update).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensee/{licenseeNumber}"
    path_params: [{name: licenseeNumber, var: licensee_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: markedForTransfer, var: marked_for_transfer}, {name: name, var: name}, {name: number, var: number}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    licensee_number: $licensee_number, active: $active, marked_for_transfer: $marked_for_transfer, name: $name, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Transfer Licenses
#
# POST /licensee/{licenseeNumber}/transfer
# Returns: record<infos: any, items: any>
# operationId: transferLicenses
export def "transfer-licenses" [
  licensee_number: string
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
  source_licensee_number: string # Licensee number which Licenses to be transferred
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensee/{licenseeNumber}/transfer"
    path_params: [{name: licenseeNumber, var: licensee_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: sourceLicenseeNumber, var: source_licensee_number}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    licensee_number: $licensee_number, source_licensee_number: $source_licensee_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate Licensee
#
# POST /licensee/{licenseeNumber}/validate
# Returns: record<infos: any, items: any>
# operationId: validateLicensee
export def "validate-licensee" [
  licensee_number: string
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
  --action: string@action-completer # 'Floating' licensing model: check-out or check-in session action, to allocate or return it from/to the pool of available sessions
  --licensee-name: string # Human-readable name for the auto-created Licensee (will be set as custom Licensee property)
  --node-secret: string # 'Node-Locked' licensing model: specifies unique secret
  --product-module-number: string # 'Node-Locked' licensing model: product module number
  --product-number: string # Product number, must be provided when 'Licensee auto-create' is enabled (see also Product JavaDoc). Identifies the Product to which new Licensee should be added
  --session-id: string # 'Floating' licensing model: specifies unique session identifier
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensee/{licenseeNumber}/validate"
    path_params: [{name: licenseeNumber, var: licensee_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: action, var: action}, {name: licenseeName, var: licensee_name}, {name: nodeSecret, var: node_secret}, {name: productModuleNumber, var: product_module_number}, {name: productNumber, var: product_number}, {name: sessionId, var: session_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    licensee_number: $licensee_number, action: $action, licensee_name: $licensee_name, node_secret: $node_secret, product_module_number: $product_module_number, product_number: $product_number, session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List License Templates
#
# GET /licensetemplate
# Returns: table<infos: any, items: any>
# operationId: listLicenseTemplates
export def "list-license-templates" [
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
    path: "/licensetemplate"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create License Template
#
# POST /licensetemplate
# Returns: record<infos: any, items: any>
# operationId: createLicenseTemplate
export def "create-license-template" [
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
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hide-licenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  license_type: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --max-sessions: string # Mandatory for 'FLOATING' License Type.
  name: string # License Template name to create License Template object
  --number: string # Unique number (across all Products of a Vendor) that identifies the License Template. Vendor can assign this number when creating a License Template or let NetLicensing generate one. Read-only after creation of the first License from this License Template.
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  product_module_number: string # Number of Product Module to create License Template object
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensetemplate"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: automatic, var: automatic}, {name: currency, var: currency}, {name: hidden, var: hidden}, {name: hideLicenses, var: hide_licenses}, {name: licenseType, var: license_type}, {name: maxSessions, var: max_sessions}, {name: name, var: name}, {name: number, var: number}, {name: price, var: price}, {name: productModuleNumber, var: product_module_number}, {name: quantity, var: quantity}, {name: quota, var: quota}, {name: timeVolume, var: time_volume}, {name: timeVolumePeriod, var: time_volume_period}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, automatic: $automatic, currency: $currency, hidden: $hidden, hide_licenses: $hide_licenses, license_type: $license_type, max_sessions: $max_sessions, name: $name, number: $number, price: $price, product_module_number: $product_module_number, quantity: $quantity, quota: $quota, time_volume: $time_volume, time_volume_period: $time_volume_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete License Template
#
# DELETE /licensetemplate/{licenseTemplateNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteLicenseTemplate
export def "delete-license-template" [
  license_template_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/licensetemplate/{licenseTemplateNumber}"
    path_params: [{name: licenseTemplateNumber, var: license_template_number}]
    query: [{name: forceCascade, var: force_cascade}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_template_number: $license_template_number, force_cascade: $force_cascade
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get License Template
#
# GET /licensetemplate/{licenseTemplateNumber}
# Returns: record<infos: any, items: any>
# operationId: getLicenseTemplate
export def "get-license-template" [
  license_template_number: string
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
    path: "/licensetemplate/{licenseTemplateNumber}"
    path_params: [{name: licenseTemplateNumber, var: license_template_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_template_number: $license_template_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update License Template
#
# POST /licensetemplate/{licenseTemplateNumber}
# Returns: record<infos: any, items: any>
# operationId: updateLicenseTemplate
export def "update-license-template" [
  license_template_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the License Template is disabled. Licensee can not obtain any new Licenses off this License Template.
  --automatic: oneof<nothing, bool> # If set to 'true', every new Licensee automatically gets one License out of this License Template on creation. Automatic Licenses must have their price set to 0.
  --currency: string # Specifies currency for the License price. Check data types to discover which currencies are supported.
  --hidden: oneof<nothing, bool> # If set to 'true', this License Template is not shown in NetLicensing Shop as offered for purchase.
  --hide-licenses: oneof<nothing, bool> # If set to 'true', Licenses from this License Template are not visible to the end customer, but participate in validation.
  --license-type: string # Type of Licenses created from this License Template. Supported types: FEATURE, TIMEVOLUME, FLOATING, QUANTITY
  --max-sessions: string # Mandatory for 'FLOATING' License Type.
  --name: string # Name for the Licensed item
  --number: string # New License Template number (update).
  --price: float # Price for the License. If >0, it must always be accompanied by the currency specification. (format: double)
  --quantity: string # Mandatory for 'Pay-per-Use' and 'Node-Locked' License Model.
  --quota: string # Mandatory for 'Quota' License Model.
  --time-volume: string # Mandatory for 'TIMEVOLUME' License Type.
  --time-volume-period: string # For 'TIMEVOLUME' License Type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/licensetemplate/{licenseTemplateNumber}"
    path_params: [{name: licenseTemplateNumber, var: license_template_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: automatic, var: automatic}, {name: currency, var: currency}, {name: hidden, var: hidden}, {name: hideLicenses, var: hide_licenses}, {name: licenseType, var: license_type}, {name: maxSessions, var: max_sessions}, {name: name, var: name}, {name: number, var: number}, {name: price, var: price}, {name: quantity, var: quantity}, {name: quota, var: quota}, {name: timeVolume, var: time_volume}, {name: timeVolumePeriod, var: time_volume_period}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    license_template_number: $license_template_number, active: $active, automatic: $automatic, currency: $currency, hidden: $hidden, hide_licenses: $hide_licenses, license_type: $license_type, max_sessions: $max_sessions, name: $name, number: $number, price: $price, quantity: $quantity, quota: $quota, time_volume: $time_volume, time_volume_period: $time_volume_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Payment Methods
#
# GET /paymentmethod
# Returns: table<infos: any, items: any>
# operationId: listPaymentMethods
export def "list-payment-methods" [
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
    path: "/paymentmethod"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Payment Method
#
# GET /paymentmethod/{paymentMethodNumber}
# Returns: record<infos: any, items: any>
# operationId: getPaymentMethod
export def "get-payment-method" [
  payment_method_number: string
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
    path: "/paymentmethod/{paymentMethodNumber}"
    path_params: [{name: paymentMethodNumber, var: payment_method_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    payment_method_number: $payment_method_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Payment Method
#
# POST /paymentmethod/{paymentMethodNumber}
# Returns: record<infos: any, items: any>
# operationId: updatePaymentMethod
export def "update-payment-method" [
  payment_method_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Payment Method is disabled.
  --paypal-subject: string # The e-mail address of the PayPal account for which you are making the API calls.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentmethod/{paymentMethodNumber}"
    path_params: [{name: paymentMethodNumber, var: payment_method_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: "paypal.subject", var: paypal_subject}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    payment_method_number: $payment_method_number, active: $active, paypal_subject: $paypal_subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Products
#
# GET /product
# Returns: table<infos: any, items: any>
# operationId: listProducts
export def "list-products" [
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
    path: "/product"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Product
#
# POST /product
# Returns: record<infos: any, items: any>
# operationId: createProduct
export def "create-product" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licensee-auto-create: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensing-info: string # Licensing information.
  name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # Unique number that identifies the Product. Vendor can assign this number when creating a Product or let NetLicensing generate one.
  --vat-mode: string@vat-mode-completer # Vat mode for Product. Supported types: GROSS, NET
  version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: description, var: description}, {name: licenseeAutoCreate, var: licensee_auto_create}, {name: licensingInfo, var: licensing_info}, {name: name, var: name}, {name: number, var: number}, {name: vatMode, var: vat_mode}, {name: version, var: version}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, description: $description, licensee_auto_create: $licensee_auto_create, licensing_info: $licensing_info, name: $name, number: $number, vat_mode: $vat_mode, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Product
#
# DELETE /product/{productNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteProduct
export def "delete-product" [
  product_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/product/{productNumber}"
    path_params: [{name: productNumber, var: product_number}]
    query: [{name: forceCascade, var: force_cascade}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_number: $product_number, force_cascade: $force_cascade
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Product
#
# GET /product/{productNumber}
# Returns: record<infos: any, items: any>
# operationId: productNumber
export def "product-number" [
  product_number: string
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
    path: "/product/{productNumber}"
    path_params: [{name: productNumber, var: product_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_number: $product_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Product
#
# POST /product/{productNumber}
# Returns: record<infos: any, items: any>
# operationId: updateProduct
export def "update-product" [
  product_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Product is disabled. No new Licensees can be registered for the Product, existing Licensees can not obtain new Licenses.
  --description: string # Product description.
  --licensee-auto-create: oneof<nothing, bool> # If set to 'true', non-existing Licensees will be created at first validation attempt.
  --licensing-info: string # Licensing information.
  --name: string # Product name. Together with the version identifies the Product for the end customer.
  --number: string # New Product number (update)
  --vat-mode: string@vat-mode-completer # Vat mode for Product. Supported types: GROSS, NET
  --version: string # Product version. Convenience parameter, additional to the Product name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/product/{productNumber}"
    path_params: [{name: productNumber, var: product_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: description, var: description}, {name: licenseeAutoCreate, var: licensee_auto_create}, {name: licensingInfo, var: licensing_info}, {name: name, var: name}, {name: number, var: number}, {name: vatMode, var: vat_mode}, {name: version, var: version}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_number: $product_number, active: $active, description: $description, licensee_auto_create: $licensee_auto_create, licensing_info: $licensing_info, name: $name, number: $number, vat_mode: $vat_mode, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Product Modules
#
# GET /productmodule
# Returns: table<infos: any, items: any>
# operationId: listProductModules
export def "list-product-modules" [
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
    path: "/productmodule"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Product Module
#
# POST /productmodule
# Returns: record<infos: any, items: any>
# operationId: createProductModule
export def "create-product-module" [
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
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --license-template: list<string> # License Template. Mandatory for 'Try & Buy' licensing model.
  licensing_model: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --max-checkout-validity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --node-secret-mode: list<string> # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  product_number: string # Unique number (across all Products of a Vendor) that identifies the Product Module. Vendor can assign this number when creating a Product Module or let NetLicensing generate one. Read-only after creation of the first Licensee for the Product.
  --red-threshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellow-threshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/productmodule"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: licenseTemplate, var: license_template}, {name: licensingModel, var: licensing_model}, {name: maxCheckoutValidity, var: max_checkout_validity}, {name: name, var: name}, {name: nodeSecretMode, var: node_secret_mode}, {name: number, var: number}, {name: productNumber, var: product_number}, {name: redThreshold, var: red_threshold}, {name: yellowThreshold, var: yellow_threshold}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, license_template: $license_template, licensing_model: $licensing_model, max_checkout_validity: $max_checkout_validity, name: $name, node_secret_mode: $node_secret_mode, number: $number, product_number: $product_number, red_threshold: $red_threshold, yellow_threshold: $yellow_threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Product Module
#
# DELETE /productmodule/{productModuleNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteProductModule
export def "delete-product-module" [
  product_module_number: string
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
  --force-cascade: oneof<nothing, bool> # Force object deletion and all descendants.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/productmodule/{productModuleNumber}"
    path_params: [{name: productModuleNumber, var: product_module_number}]
    query: [{name: forceCascade, var: force_cascade}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_module_number: $product_module_number, force_cascade: $force_cascade
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Product Module
#
# GET /productmodule/{productModuleNumber}
# Returns: record<infos: any, items: any>
# operationId: getProductModule
export def "get-product-module" [
  product_module_number: string
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
    path: "/productmodule/{productModuleNumber}"
    path_params: [{name: productModuleNumber, var: product_module_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_module_number: $product_module_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Product Module
#
# POST /productmodule/{productModuleNumber}
# Returns: record<infos: any, items: any>
# operationId: updateProductModule
export def "update-product-module" [
  product_module_number: string
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
  --active: oneof<nothing, bool> # If set to 'false', the Product Module is disabled. Licensees can not obtain any new Licenses for this Product Module.
  --license-template: list<string> # License Template. Mandatory for 'Try & Buy' licensing model.
  --licensing-model: string # Licensing model applied to this Product Module. Defines what License Templates can be configured for the Product Module and how Licenses for this Product Module are processed during validation.
  --max-checkout-validity: int # Maximum checkout validity (days). Mandatory for 'Floating' licensing model. (format: int32)
  --name: string # Product Module name that is visible to the end customers in NetLicensing Shop.
  --node-secret-mode: list<string> # Secret Mode. Mandatory for 'Node-Locked' licensing model.
  --number: string # New Product Module number (update).
  --red-threshold: int # Remaining time volume for red level. Mandatory for 'Rental' licensing model. (format: int32)
  --yellow-threshold: int # Remaining time volume for yellow level. Mandatory for 'Rental' licensing model. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/productmodule/{productModuleNumber}"
    path_params: [{name: productModuleNumber, var: product_module_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: licenseTemplate, var: license_template}, {name: licensingModel, var: licensing_model}, {name: maxCheckoutValidity, var: max_checkout_validity}, {name: name, var: name}, {name: nodeSecretMode, var: node_secret_mode}, {name: number, var: number}, {name: redThreshold, var: red_threshold}, {name: yellowThreshold, var: yellow_threshold}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    product_module_number: $product_module_number, active: $active, license_template: $license_template, licensing_model: $licensing_model, max_checkout_validity: $max_checkout_validity, name: $name, node_secret_mode: $node_secret_mode, number: $number, red_threshold: $red_threshold, yellow_threshold: $yellow_threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Tokens
#
# GET /token
# Returns: table<infos: any, items: any>
# operationId: listTokens
export def "list-tokens" [
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
    path: "/token"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create token
#
# POST /token
# Returns: record<infos: any, items: any>
# operationId: createToken
export def "create-token" [
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
  --action: string@action-completer-1 # For type=ACTION only; defines token action to be perfromed
  --api-key-role: string@api-key-role-completer # For tokenType=APIKEY only (default: ROLE_APIKEY_LICENSEE); defines token RoleID
  --cancel-url: string # For tokenType=SHOP only; take customers to this URL when they cancel their checkout
  --cancel-url-title: string # For tokenType=SHOP only; shop link title for cancel checkout process
  --license-template-number: string # For tokenType=SHOP only; identifies LicenseTemplate that will be assigned to the shop token
  --licensee-number: string # For tokenType=SHOP or type=ACTION only (mandatory); identifies Licensee that will be assigned to the shop token
  --predefined-shopping-item: string # For tokenType=SHOP only; identifies Shopping Item name that will be shown to the customer
  --private-key: string # For tokenType=APIKEY only (optional); defines PrivateKey to be used with the validate methodPlease Note: PrivateKey need to be provided as one line without spaces
  --product-number: string # For tokenType=SHOP only (mandatory); identifies Product that will be assigned to the shop token
  --success-url: string # For tokenType=SHOP only; take customers to this URL when they finish checkout
  --success-url-title: string # For tokenType=SHOP only; shop link title for successful checkout process
  token_type: string@token-type-completer # Token type to be generated
  --type: string@type-completer # For tokenType=DEFAULT only; action type to be set
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: action, var: action}, {name: apiKeyRole, var: api_key_role}, {name: cancelURL, var: cancel_url}, {name: cancelURLTitle, var: cancel_url_title}, {name: licenseTemplateNumber, var: license_template_number}, {name: licenseeNumber, var: licensee_number}, {name: predefinedShoppingItem, var: predefined_shopping_item}, {name: privateKey, var: private_key}, {name: productNumber, var: product_number}, {name: successURL, var: success_url}, {name: successURLTitle, var: success_url_title}, {name: tokenType, var: token_type}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    action: $action, api_key_role: $api_key_role, cancel_url: $cancel_url, cancel_url_title: $cancel_url_title, license_template_number: $license_template_number, licensee_number: $licensee_number, predefined_shopping_item: $predefined_shopping_item, private_key: $private_key, product_number: $product_number, success_url: $success_url, success_url_title: $success_url_title, token_type: $token_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete token
#
# DELETE /token/{tokenNumber}
# Returns: record<infos: any, items: any>
# operationId: deleteToken
export def "delete-token" [
  token_number: string
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
    method: delete
    path: "/token/{tokenNumber}"
    path_params: [{name: tokenNumber, var: token_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    token_number: $token_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get token
#
# GET /token/{tokenNumber}
# Returns: record<infos: any, items: any>
# operationId: getToken
export def "get-token" [
  token_number: string
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
    path: "/token/{tokenNumber}"
    path_params: [{name: tokenNumber, var: token_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    token_number: $token_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Transactions
#
# GET /transaction
# Returns: table<infos: any, items: any>
# operationId: listTransactions
export def "list-transactions" [
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
    path: "/transaction"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Transaction
#
# POST /transaction
# Returns: record<infos: any, items: any>
# operationId: createTransaction
export def "create-transaction" [
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
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --date-closed: string # format: date-time
  --date-created: string # format: date-time
  --licensee-number: string
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --payment-method: string
  source: string@source-completer # AUTO Transaction for internal use only
  status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transaction"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active, required: true}, {name: dateClosed, var: date_closed}, {name: dateCreated, var: date_created}, {name: licenseeNumber, var: licensee_number}, {name: number, var: number}, {name: paymentMethod, var: payment_method}, {name: source, var: source}, {name: status, var: status}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    active: $active, date_closed: $date_closed, date_created: $date_created, licensee_number: $licensee_number, number: $number, payment_method: $payment_method, source: $source, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Transaction
#
# GET /transaction/{transactionNumber}
# Returns: record<infos: any, items: any>
# operationId: getTransaction
export def "get-transaction" [
  transaction_number: string
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
    path: "/transaction/{transactionNumber}"
    path_params: [{name: transactionNumber, var: transaction_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    transaction_number: $transaction_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Transaction
#
# POST /transaction/{transactionNumber}
# Returns: record<infos: any, items: any>
# operationId: updateTransaction
export def "update-transaction" [
  transaction_number: string
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
  --active: oneof<nothing, bool> # Always 'true' for Transactions
  --date-closed: string # format: date-time
  --date-created: string # format: date-time
  --number: string # Unique number (across all Products of a Vendor) that identifies the Transaction
  --payment-method: string
  --source: string@source-completer # AUTO Transaction for internal use only
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transaction/{transactionNumber}"
    path_params: [{name: transactionNumber, var: transaction_number}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: active, var: active}, {name: dateClosed, var: date_closed}, {name: dateCreated, var: date_created}, {name: number, var: number}, {name: paymentMethod, var: payment_method}, {name: source, var: source}, {name: status, var: status}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    transaction_number: $transaction_number, active: $active, date_closed: $date_closed, date_created: $date_created, number: $number, payment_method: $payment_method, source: $source, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List License Types
#
# GET /utility/licenseTypes
# Returns: record<infos: any, items: any>
# operationId: licenseTypes
export def "license-types" [
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
    path: "/utility/licenseTypes"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Licensing Models
#
# GET /utility/licensingModels
# Returns: record<infos: any, items: any>
# operationId: licensingModels
export def "licensing-models" [
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
    path: "/utility/licensingModels"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
