# Auto-generated client for REST API Version 2 v2.9.235
# Source: https://api.apis.guru/v2/specs/circuitsandbox.net/2.9.235/openapi.json
# Auth: --token flag or $env.REST_API_VERSION_2_TOKEN

const CLIENT = {
  base_url: "https://circuitsandbox.net/rest/v2"
  token_env_var: "REST_API_VERSION_2_TOKEN"
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

def base-url-completer [] { ["https://circuitsandbox.net/rest/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["AFTER" "BEFORE"] }
def accept-completer [] { ["application/json" "application/xml"] }
def sort-completer [] { ["ALPHABETICALLY" "POPULARITY" "RECENT_ACTIVITY"] }
def order-completer [] { ["ASCENDING" "DESCENDING"] }
def scope-completer [] { ["ALL" "CONVERSATIONS" "FILES" "FILTER" "LABEL" "MEMBERS" "MESSAGES" "PEOPLE" "SENTBY"] }
def type-completer [] { ["BOT" "FORMER" "GUEST" "MODERATOR" "REGULAR"] }
def access-mode-type-completer [] { ["INTERNAL_EXTERNAL" "INTERNAL_ONLY"] }
def role-completer [] { ["AUTHOR" "MODERATOR" "PARTICIPANT" "READER"] }
def status-completer [] { ["DISABLED" "ENABLED"] }
def type-completer-1 [] { ["CLOSED" "OPEN" "SECRET"] }
def sort-by-completer [] { ["CREATION_DATE" "LAST_CONTENT" "NAME" "NUMBER_OF_USERS"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def filter-completer [] { ["CLOSED" "JOINED" "NONE" "NOT_JOINED_REQUESTED" "OPEN" "REQUESTED"] }
def search-direction-completer [] { ["AFTER" "BEFORE"] }
def scope-completer-1 [] { ["ALL" "DATE" "FILES" "LABELS" "SPACES" "TAGS" "TOPICBY"] }
def access-mode-type-completer-1 [] { ["INTERNAL_EXTERNAL" "INTERNAL_ONLY" "NO_CHANGE"] }
def role-completer-1 [] { ["AUTHOR" "MODERATOR" "NO_CHANGE" "PARTICIPANT" "READER"] }
def type-completer-2 [] { ["CLOSED" "NO_CHANGE" "OPEN" "SECRET"] }
def role-completer-2 [] { ["AUTHOR" "DEFAULT" "MODERATOR" "PARTICIPANT" "READER"] }
def sort-by-completer-1 [] { ["DISPLAY_NAME" "FIRST_NAME" "NAME"] }
def filter-type-completer [] { ["ACCESS_TYPE" "NONE" "ROLE" "STATE"] }
def direction-completer-1 [] { ["AFTER" "BEFORE" "BOTH"] }
def journal-filter-completer [] { ["ALL" "DIALED" "DIVERTED" "MISSED" "RECEIVED" "UNHERAD_VOICEMAILS" "VOICEMAILS"] }
def locale-completer [] { ["CA_ES" "DE_DE" "EN_GB" "EN_US" "ES_ES" "FR_FR" "IT_IT" "NL_NL" "PT_BR" "RU_RU" "ZH_HANS_CN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-conversations: "table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-conversations-by-id: "table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-community-conversations: "table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    create-community-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    update-conversation-community: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    join-community-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    remove-participant-community: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    add-participant-community: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-join-details-multiple: "table<bridgeNumbers: list<record>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string>"
    get-direct-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    create-direct-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-favorite-conversations: "table<CASE_INSENSITIVE_ORDER: any>"
    create-group-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    update-conversation-group: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    remove-participant-group: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    add-participant-group: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-conversations-by-label: "record<conversationList: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list, topic: string, topicPlaceholder: string, type: string>, hasMore: any, nextPagePointer: string>"
    get-flag-item-conv: "table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>"
    get-single-conversationtem: "record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>"
    resolve-invitation-token: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    search-conversations: "record<matchingConversations: table<convId: string, itemIds: list>>"
    get-conversationby-id: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-join-details: "record<bridgeNumbers: table<bridgeNumber: string, country: string, isMostUsed: bool, locale: string, name: string, type: string>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string>"
    get-conversation-items: "table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>"
    assign-label: "record<labelId: string, value: string>"
    unassign-label: "record<labelId: string, value: string>"
    add-text-item: "record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>"
    get-flag-item: "table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>"
    delete-text-item: "record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>"
    add-text-item-with-parent: "record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>"
    update-text-item: "record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>"
    get-participants-by-conv-id: "table<hasMore: bool, participantList: list<record>, searchPointer: string>"
    get-pinned-conversations: "table<conversationId: string, conversationItemId: string, pinnedTime: float>"
    un-pin-a-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    pin-a-conversation: "record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>"
    get-active-sessions: "record<labelId: string, value: string>"
    get-directory: "record<hasMore: bool, searchPointer: string, spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>>"
    get-flagged-items: "record<flaggedItems: table<item: record, parentItem: record>, hasMore: bool, searchPointer: string>"
    get-likes: "record<hasMore: bool, participants: table<firstName: string, largeImageUri: string, lastName: string, smallImageUri: string, userId: string>, searchPointer: string>"
    get-recent-searches: "table<resList: list<record>>"
    start-basic-spaces-search: "record<spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>, status: string>"
    start-detailed-space-search: "table<resList: list<record>>"
    update-topic-tags: "record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>"
    assign-labels: "table<labelIds: list<string>>"
    unassign-labels: "table<labelIds: list<string>>"
    add-participants-to-space: "list<any>"
    get-space-participants: "record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string>"
    get-pending-participants: "record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string>"
    get-pinned-topics: "table<position: float, subject: string, topicId: string>"
    search-participants-to-add: "table<department: string, firstName: string, isMember: bool, jobTitle: string, lastName: string, smallImageUri: string, tenantId: string, userId: string>"
    search-space-participants: "table<hasMore: bool, participants: list<record>, searchPointer: string>"
    get-participants-import-data: "record<actualNumberOfImportedParticipants: float, estimatedImportDuration: float, importEndDate: float, importFileId: string, importFileName: string, importProgress: float, importStartDate: float, importStatus: string, plannedNumberOfImportedParticipants: float, resultFileId: string, resultFileName: string>"
    create-space-topic: "record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>"
    v2-get-topic-with-replies: "record<replies: table<parentTopicId: string, spaceItem: record>, topic: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>>>"
    update-space-topic: "record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>"
    get-space-replies: "record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>"
    create-reply: "record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>"
    update-space-reply: "record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>"
    get-space-topics: "table<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>>"
    v2-get-device-infos: "table<clientId: string, clientVersion: string, deviceSubtype: string, deviceType: string, hardwareModel: string, homeNode: string, manufacturer: string, osVersion: string, userId: string>"
    get-journal-entries: "table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>"
    search-user: "table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    get-label: "table<labelId: string, value: string>"
    add-label: "record<labelId: string, value: string>"
    remove-label: "record<labelId: string, value: string>"
    search-users-list: "table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    get-presence: "table<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>"
    set-user-presence: "record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>"
    get-profile: "record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    update-profile: "record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    get-support-info: "record<supportEmailAddress: string, supportType: any>"
    get-user-by-email-address: "record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    get-user-by-id: "record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>"
    get-user-presence: "record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>"
    get-web-hook: "table<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
    add-web-hook: "record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
    create-incoming-webhook: "record<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string>"
    get-incoming-webhook-by-user: "table<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string>"
    add-presence-web-hook: "record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
    update-presence-web-hook: "record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
    get-web-hook-by-id: "record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
    update-web-hook: "record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-conversations" "get-conversations-by-id" "get-community-conversations" "create-community-conversation" "update-conversation-community" "join-community-conversation" "remove-participant-community" "add-participant-community" "get-join-details-multiple" "get-direct-conversation" "create-direct-conversation" "get-favorite-conversations" "create-group-conversation" "update-conversation-group" "remove-participant-group" "add-participant-group" "get-conversations-by-label" "get-flag-item-conv" "get-single-conversationtem" "moderate-conversation" "resolve-invitation-token" "search-conversations" "unmoderate-conversation" "get-conversationby-id" "undo-archive-conversation" "archive-conversation" "get-join-details" "delete-favorite" "add-favorite" "get-conversation-items" "assign-label" "unassign-label" "add-text-item" "get-flag-item" "delete-text-item" "add-text-item-with-parent" "update-text-item" "un-flag-item" "flag-item" "unlike-item" "like-item" "remove-moderators" "add-moderators" "get-participants-by-conv-id" "get-pinned-conversations" "un-pin-a-conversation" "pin-a-conversation" "get-active-sessions" "get-spaces" "create-space" "get-directory" "exists-space-name" "flag-space-item" "get-flagged-items" "get-spaces-by-ids" "delete-space-item" "like-space-item" "get-likes" "add-recent-space-search" "cancel-space-search" "get-recent-searches" "start-basic-spaces-search" "start-detailed-space-search" "update-topic-tags" "unflag-space-item" "unlike-space-item" "delete-space" "update-space" "join-space" "assign-labels" "unassign-labels" "leave-space" "add-participants-to-space" "v2-remove-participants-from-space" "get-space-participants" "get-pending-participants" "get-pinned-topics" "search-participants-to-add" "search-space-participants" "update-read-timestamp" "update-participant-in-space" "get-participants-import-data" "request-space-acces" "deny-space-acces" "grant-space-acces" "create-space-topic" "v2-get-topic-with-replies" "update-space-topic" "get-space-replies" "create-reply" "update-space-reply" "get-space-topics" "v2-update-welcome-box-content" "pin-topic" "unpin-topic" "v2-get-device-infos" "v2-get-telephony-conversation-id" "get-journal-entries" "search-user" "get-label" "add-label" "remove-label" "search-users-list" "get-presence" "set-user-presence" "get-profile" "update-profile" "get-support-info" "get-user-by-email-address" "get-user-by-id" "get-user-presence" "remove-web-hooks" "get-web-hook" "add-web-hook" "create-incoming-webhook" "get-incoming-webhook-by-user" "delete-incoming-webhook" "post-webhook-as-slack-message" "add-presence-web-hook" "update-presence-web-hook" "remove-web-hook" "get-web-hook-by-id" "update-web-hook" "commands"] | sort) } | get name | first)
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

# Gets a list of conversations
#
# GET /conversations
# Returns: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: getConversations
export def "get-conversations" [
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
  --mod-time: string # The modification time of the conversation in UTC format. During the query the conversations before (default) or after this timestamp are returned. In case no timestamp is specified the current server time in UTC is used, i.e. the last 25 modified conversations are returned (format: date-time)
  --direction: string@direction-completer # The direction of the search based on the modification time. Valid values are either BEFORE (default) or AFTER (default: BEFORE)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations"
    query: [{name: modTime, var: mod_time}, {name: direction, var: direction}, {name: results, var: results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    mod_time: $mod_time, direction: $direction, results: $results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets conversations
#
# GET /conversations/byIds
# Returns: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: getConversationsById
export def "get-conversations-by-id" [
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
  --conv-ids: list<string> # The array of IDs of the conversations which should be retrieved (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/byIds"
    query: [{name: convIds, var: conv_ids, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_ids: $conv_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of communities
#
# GET /conversations/community
# Returns: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: getCommunityConversations
export def "get-community-conversations" [
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
  --sort: string@sort-completer # Defines the type of sorting for the community conversations (default is alphabetical) (default: ALPHABETICALLY)
  --order: string@order-completer # Defines the ordering of the conversations (default is ascending) (default: ASCENDING)
  --include-own: oneof<nothing, bool> # If set to false only conversations are returned where the user is no member of, otherwise all community conversations are returned (default: false)
  --start-index: float # The index of the conversation that is the first one that has to be returned. E.g. if a request starts with startIndex 40 and results 20 the conversations 40 to 60 are returned (format: int32, default: 0)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/community"
    query: [{name: sort, var: sort}, {name: order, var: order}, {name: includeOwn, var: include_own}, {name: startIndex, var: start_index}, {name: results, var: results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, order: $order, include_own: $include_own, start_index: $start_index, results: $results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a community conversation
#
# POST /conversations/community
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: createCommunityConversation
export def "create-community-conversation" [
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
  --description: string # An optional description for the community conversation
  --participants: list<string> # list of participants that will be part of this conversation, specified by the Circuit user ID or the unique email address. At least one participant needs to be added
  topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/community"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}, {name: participants, var: participants}, {name: topic, var: topic}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, participants: $participants, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the information of a community
#
# PUT /conversations/community/{convId}
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: updateConversationCommunity
export def "update-conversation-community" [
  conv_id: string
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
  --description: string # An optional description for the community conversation
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversations/community/{convId}"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}, {name: topic, var: topic}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, description: $description, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds the authenticated user to a community
#
# POST /conversations/community/{convId}/join
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: joinCommunityConversation
export def "join-community-conversation" [
  conv_id: string
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
    method: post
    path: "/conversations/community/{convId}/join"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes participants from a community
#
# DELETE /conversations/community/{convId}/participants
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: removeParticipantCommunity
export def "remove-participant-community" [
  conv_id: string
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
  --participants: list<string> # The IDs or the unique email addresses of the Circuit users that have to be removed (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/conversations/community/{convId}/participants"
    path_params: [{name: convId, var: conv_id}]
    query: [{name: participants, var: participants, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, participants: $participants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds participants to a community
#
# POST /conversations/community/{convId}/participants
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: addParticipantCommunity
export def "add-participant-community" [
  conv_id: string
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
  participants: list<string> # The IDs or the unique email addresses of the Circuit users that should to be added.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/community/{convId}/participants"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: participants, var: participants}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, participants: $participants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the conference details for multiple conversations
#
# GET /conversations/conversationdetails
# Returns: table<bridgeNumbers: list<record>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string>
# operationId: getJoinDetailsMultiple
export def "get-join-details-multiple" [
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
  --conv-ids: list<string> # An array of IDs of the conversations for which the join details should be returned (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/conversationdetails"
    query: [{name: convIds, var: conv_ids, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_ids: $conv_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks for a 1-to-1 conversation
#
# GET /conversations/direct
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: getDirectConversation
export def "get-direct-conversation" [
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
  --participant: string # The participant that will be part of this conversation together with the creator, specified by the Circuit user ID or the unique email address (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/direct"
    query: [{name: participant, var: participant, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    participant: $participant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a 1-to-1 conversation
#
# POST /conversations/direct
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: createDirectConversation
export def "create-direct-conversation" [
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
  participant: string # The participant that will be part of this conversation together with the creator, specified by the Circuit user ID or the unique email address
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/direct"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: participant, var: participant}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    participant: $participant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets favorite conversations
#
# GET /conversations/favorite
# Returns: table<CASE_INSENSITIVE_ORDER: any>
# operationId: getFavoriteConversations
export def "get-favorite-conversations" [
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
    path: "/conversations/favorite"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a group conversation
#
# POST /conversations/group
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: createGroupConversation
export def "create-group-conversation" [
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
  participants: list<string> # A list of participants that will be part of this conversation, specified by the Circuit user ID or the unique email address. At least one participant needs to be added
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/group"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: participants, var: participants}, {name: topic, var: topic}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    participants: $participants, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the information of a group conversation
#
# PUT /conversations/group/{convId}
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: updateConversationGroup
export def "update-conversation-group" [
  conv_id: string
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
  --topic: string # An optional topic of the conversation. If not set the Circuit client will render the names of the participants as topic of the conversation (the first 4 names will be used)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversations/group/{convId}"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: topic, var: topic}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes participants from a group conversation
#
# DELETE /conversations/group/{convId}/participants
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: removeParticipantGroup
export def "remove-participant-group" [
  conv_id: string
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
  --participants: list<string> # The IDs or the unique email addresses of the Circuit users that have to be removed (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/conversations/group/{convId}/participants"
    path_params: [{name: convId, var: conv_id}]
    query: [{name: participants, var: participants, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, participants: $participants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds participants to a group conversation
#
# POST /conversations/group/{convId}/participants
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: addParticipantGroup
export def "add-participant-group" [
  conv_id: string
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
  participants: list<string> # The IDs or the unique email addresses of the Circuit users that should to be added.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/group/{convId}/participants"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: participants, var: participants}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, participants: $participants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns conversations with a certain label
#
# GET /conversations/label/{labelId}
# Returns: record<conversationList: table<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list, topic: string, topicPlaceholder: string, type: string>, hasMore: any, nextPagePointer: string>
# operationId: getConversationsByLabel
export def "get-conversations-by-label" [
  label_id: string
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
  --next-page-pointer: string # Pointer to the next page of conversations if there are any
  --page-size: float # Numbers of max conversations per page (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/label/{labelId}"
    path_params: [{name: labelId, var: label_id}]
    query: [{name: nextPagePointer, var: next_page_pointer}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    label_id: $label_id, next_page_pointer: $next_page_pointer, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of the flagged messages
#
# GET /conversations/messages/flag
# Returns: table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>
# operationId: getFlagItemConv
export def "get-flag-item-conv" [
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
    path: "/conversations/messages/flag"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a text item
#
# GET /conversations/messages/{itemId}
# Returns: record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>
# operationId: getSingleConversationtem
export def "get-single-conversationtem" [
  item_id: string
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
    path: "/conversations/messages/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set conversation moderated
#
# POST /conversations/moderate/{convId}
# operationId: moderateConversation
export def "moderate-conversation" [
  conv_id: string
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
    path: "/conversations/moderate/{convId}"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolves an invite token to a conversation
#
# GET /conversations/resolveinvitetoken
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: resolveInvitationToken
export def "resolve-invitation-token" [
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
  --qp-token: string # The invite token to resolve (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/resolveinvitetoken"
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Performs a conversation search
#
# GET /conversations/search
# Returns: record<matchingConversations: table<convId: string, itemIds: list>>
# operationId: searchConversations
export def "search-conversations" [
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
  --term: string # The search term (required)
  --include-item-ids: oneof<nothing, bool> # Optional parameter to specify if a deep or normal search is executed. In a deep search all matching item IDs inside every conversation are returned (up to a maximum of 100). For a normal search only the conversation IDs are returned. Default is a normal search (without item IDs). (default: false)
  --scope: string@scope-completer # The search scope, FILES||PEOPLE||MEMBERS||MESSAGES||SENTBY||ALL||CONVERSATIONS||LABEL||FILTER (default: ALL)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/search"
    query: [{name: term, var: term, required: true}, {name: includeItemIds, var: include_item_ids}, {name: scope, var: scope}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    term: $term, include_item_ids: $include_item_ids, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set conversation unmoderated
#
# POST /conversations/unmoderate/{convId}
# operationId: unmoderateConversation
export def "unmoderate-conversation" [
  conv_id: string
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
    path: "/conversations/unmoderate/{convId}"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a conversation
#
# GET /conversations/{convId}
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: getConversationbyId
export def "get-conversationby-id" [
  conv_id: string
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
    path: "/conversations/{convId}"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unmute conversation
#
# DELETE /conversations/{convId}/archive
# operationId: undoArchiveConversation
export def "undo-archive-conversation" [
  conv_id: string
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
    path: "/conversations/{convId}/archive"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives conversation
#
# POST /conversations/{convId}/archive
# operationId: archiveConversation
export def "archive-conversation" [
  conv_id: string
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
    path: "/conversations/{convId}/archive"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the conference details of a conversation
#
# GET /conversations/{convId}/conversationdetails
# Returns: record<bridgeNumbers: table<bridgeNumber: string, country: string, isMostUsed: bool, locale: string, name: string, type: string>, convId: string, conversationCreatorId: string, isModerationAllowed: bool, isRecordingAllowed: bool, link: string, pin: string>
# operationId: getJoinDetails
export def "get-join-details" [
  conv_id: string
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
    path: "/conversations/{convId}/conversationdetails"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes a conversation from favorites
#
# DELETE /conversations/{convId}/favorite
# operationId: deleteFavorite
export def "delete-favorite" [
  conv_id: string
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
    path: "/conversations/{convId}/favorite"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a conversation to the favorites
#
# POST /conversations/{convId}/favorite
# operationId: addFavorite
export def "add-favorite" [
  conv_id: string
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
    path: "/conversations/{convId}/favorite"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of conversation items
#
# GET /conversations/{convId}/items
# Returns: table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>
# operationId: getConversationItems
export def "get-conversation-items" [
  conv_id: string
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
  --mod-time: string # The modification time of the item in UTC format. During the query the items before (default) or after this timestamps are returned. In case no timestamp is specified the current server time in UTC is used, i.e. the last 25 modified items are returned (format: date-time)
  --direction: string@direction-completer # The direction of the search based on the modification time. Valid values are either BEFORE (default) or AFTER (default: BEFORE)
  --results: float # The maximum number of returned results (default 25). The maximum allowed value is 100. (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/{convId}/items"
    path_params: [{name: convId, var: conv_id}]
    query: [{name: modTime, var: mod_time}, {name: direction, var: direction}, {name: results, var: results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, mod_time: $mod_time, direction: $direction, results: $results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a label to a conversation
#
# POST /conversations/{convId}/label
# Returns: record<labelId: string, value: string>
# operationId: assignLabel
export def "assign-label" [
  conv_id: string
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
  label: string # The actual label
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{convId}/label"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: label, var: label}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes a label from a conversation
#
# DELETE /conversations/{convId}/label/{labelId}
# Returns: record<labelId: string, value: string>
# operationId: unassignLabel
export def "unassign-label" [
  conv_id: string
  label_id: string
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
    path: "/conversations/{convId}/label/{labelId}"
    path_params: [{name: convId, var: conv_id}, {name: labelId, var: label_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a message to a conversation
#
# POST /conversations/{convId}/messages
# Returns: record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>
# operationId: addTextItem
export def "add-text-item" [
  conv_id: string
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
  --attachments: list<string> # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item, is mandatory unless an attachment is added
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{convId}/messages"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: content, var: content}, {name: formMetaData, var: form_meta_data}, {name: subject, var: subject}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, attachments: $attachments, content: $content, form_meta_data: $form_meta_data, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of the flagged messages of a conversation
#
# GET /conversations/{convId}/messages/flag
# Returns: table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>
# operationId: getFlagItem
export def "get-flag-item" [
  conv_id: string
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
    path: "/conversations/{convId}/messages/flag"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a message from a conversation
#
# DELETE /conversations/{convId}/messages/{itemId}
# Returns: record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>
# operationId: deleteTextItem
export def "delete-text-item" [
  conv_id: string
  item_id: string
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
    path: "/conversations/{convId}/messages/{itemId}"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a message to an item
#
# POST /conversations/{convId}/messages/{itemId}
# Returns: record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>
# operationId: addTextItemWithParent
export def "add-text-item-with-parent" [
  conv_id: string
  item_id: string
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
  --attachments: list<string> # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{convId}/messages/{itemId}"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: content, var: content}, {name: formMetaData, var: form_meta_data}, {name: subject, var: subject}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id, attachments: $attachments, content: $content, form_meta_data: $form_meta_data, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a message
#
# PUT /conversations/{convId}/messages/{itemId}
# Returns: record<attachments: table<creationTime: float, creatorId: string, deleteUrl: string, fileId: string, fileName: string, itemId: string, mimeType: string, modificationTime: float, size: float, url: string>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record<duration: float, maxNumberOfAttendees: float, pickFromParticipant: string>, missed: string, moved: record<conversationId: string, direction: string>, rtcParticipants: list<record>, type: string>, system: record<affectedParticipants: list<string>, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list<string>, parentId: string, preview: record<imageURI: string, srcURL: string, title: string, type: string>, state: string, subject: string>, type: string>
# operationId: updateTextItem
export def "update-text-item" [
  conv_id: string
  item_id: string
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
  --attachments: list<string> # A comma separated list of attachment IDs from the file API.
  --content: string # The actual content of the item
  --form-meta-data: string # The form meta data of the new text item
  --subject: string # The subject (headline) of the new text item
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/conversations/{convId}/messages/{itemId}"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: content, var: content}, {name: formMetaData, var: form_meta_data}, {name: subject, var: subject}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id, attachments: $attachments, content: $content, form_meta_data: $form_meta_data, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the flag from a message
#
# DELETE /conversations/{convId}/messages/{itemId}/flag
# operationId: unFlagItem
export def "un-flag-item" [
  conv_id: string
  item_id: string
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
    path: "/conversations/{convId}/messages/{itemId}/flag"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a flag to a message in a conversation
#
# POST /conversations/{convId}/messages/{itemId}/flag
# operationId: flagItem
export def "flag-item" [
  conv_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-creation-time: string # The time when the item was created
  --parent-id: string # The ID of the item's parent
]: any -> any {
  $in | http-request {
    method: post
    path: "/conversations/{convId}/messages/{itemId}/flag"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: itemCreationTime, var: item_creation_time}, {name: parentId, var: parent_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id, item_creation_time: $item_creation_time, parent_id: $parent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a "like" from a message
#
# DELETE /conversations/{convId}/messages/{itemId}/like
# operationId: unlikeItem
export def "unlike-item" [
  conv_id: string
  item_id: string
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
    path: "/conversations/{convId}/messages/{itemId}/like"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a "like" to a message
#
# POST /conversations/{convId}/messages/{itemId}/like
# operationId: likeItem
export def "like-item" [
  conv_id: string
  item_id: string
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
    path: "/conversations/{convId}/messages/{itemId}/like"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove moderators
#
# DELETE /conversations/{convId}/moderators
# operationId: removeModerators
export def "remove-moderators" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderators: list<string> # The list of moderator ids to remove
]: any -> any {
  $in | http-request {
    method: delete
    path: "/conversations/{convId}/moderators"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: moderators, var: moderators}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, moderators: $moderators
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add moderators
#
# POST /conversations/{convId}/moderators
# operationId: addModerators
export def "add-moderators" [
  conv_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderators: list<string> # The list of moderator ids to add
]: any -> any {
  $in | http-request {
    method: post
    path: "/conversations/{convId}/moderators"
    path_params: [{name: convId, var: conv_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: moderators, var: moderators}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, moderators: $moderators
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a list of participants
#
# GET /conversations/{convId}/participants
# Returns: table<hasMore: bool, participantList: list<record>, searchPointer: string>
# operationId: getParticipantsByConvId
export def "get-participants-by-conv-id" [
  conv_id: string
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
  --page-size: float # The page size of the hit list (required, format: int32)
  --name: string # Part of name to filter the results
  --type: string@type-completer # Type of participant to filter the results (default: REGULAR)
  --search-pointer: string # Pointer for paged output. Add to consecutive request to get next page
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/{convId}/participants"
    path_params: [{name: convId, var: conv_id}]
    query: [{name: pageSize, var: page_size, required: true}, {name: name, var: name}, {name: type, var: type}, {name: searchPointer, var: search_pointer}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, page_size: $page_size, name: $name, type: $type, search_pointer: $search_pointer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns pinned topics of a conversation
#
# GET /conversations/{convId}/pins
# Returns: table<conversationId: string, conversationItemId: string, pinnedTime: float>
# operationId: getPinnedConversations
export def "get-pinned-conversations" [
  conv_id: string
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
    path: "/conversations/{convId}/pins"
    path_params: [{name: convId, var: conv_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unpins a topic of a conversation
#
# DELETE /conversations/{convId}/pins/{itemId}
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: unPinAConversation
export def "un-pin-a-conversation" [
  conv_id: string
  item_id: string
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
    path: "/conversations/{convId}/pins/{itemId}"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Pins a topic of a conversation
#
# POST /conversations/{convId}/pins/{itemId}
# Returns: record<avatar: string, avatarLarge: string, convId: string, creationTime: float, creatorId: string, creatorTenantId: string, description: string, isGuestAccessDisabled: bool, isModerated: bool, modificationTime: float, participants: list<string>, topic: string, topicPlaceholder: string, type: string>
# operationId: pinAConversation
export def "pin-a-conversation" [
  conv_id: string
  item_id: string
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
    method: post
    path: "/conversations/{convId}/pins/{itemId}"
    path_params: [{name: convId, var: conv_id}, {name: itemId, var: item_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conv_id: $conv_id, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of active sessions
#
# GET /rtc/sessions
# Returns: record<labelId: string, value: string>
# operationId: getActiveSessions
export def "get-active-sessions" [
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
    path: "/rtc/sessions"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the spaces
#
# GET /spaces
# operationId: getSpaces
export def "get-spaces" [
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
  --timestamp: string # a beautiful timestamp (format: date-time)
  --number-of-results: float # the number of results you want (format: int32)
]: nothing -> any {
  http-request {
    method: get
    path: "/spaces"
    query: [{name: timestamp, var: timestamp}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    timestamp: $timestamp, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a space
#
# POST /spaces/create
# operationId: createSpace
export def "create-space" [
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
  access_mode_type: string@access-mode-type-completer # Access mode (default: INTERNAL_ONLY)
  --description: string # description of the space
  --large-picture-base64: string # large picture
  name: string # name of the space
  role: string@role-completer # role (default: AUTHOR)
  --small-picture-base64: string # small picture
  status: string@status-completer # status (default: ENABLED)
  --tags: list<string> # tags of the space
  type: string@type-completer-1 # type (default: SECRET)
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/create"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: accessModeType, var: access_mode_type}, {name: description, var: description}, {name: largePictureBase64, var: large_picture_base64}, {name: name, var: name}, {name: role, var: role}, {name: smallPictureBase64, var: small_picture_base64}, {name: status, var: status}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    access_mode_type: $access_mode_type, description: $description, large_picture_base64: $large_picture_base64, name: $name, role: $role, small_picture_base64: $small_picture_base64, status: $status, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the directory
#
# GET /spaces/directory
# Returns: record<hasMore: bool, searchPointer: string, spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>>
# operationId: getDirectory
export def "get-directory" [
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
  --sort-by: string@sort-by-completer # sort the spaces by LAST_CONTENT, NAME, NUMBER_OF_USERS or CREATION_DATE (required, default: LAST_CONTENT)
  --sort-order: string@sort-order-completer # ascending or descending (required, default: ASCENDING)
  --filter: string@filter-completer # filter for spaces (JOINED, REQUESTED, OPEN, CLOSED or NOT_JOINED_REQUESTED) (required, default: NONE)
  --query: string # some sort of query
  --page-pointer: string # page pointer, start with nothing and for next query use returned pointer
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/directory"
    query: [{name: sortBy, var: sort_by, required: true, default: LAST_CONTENT}, {name: sortOrder, var: sort_order, required: true, default: ASCENDING}, {name: filter, var: filter, required: true, default: NONE}, {name: query, var: query}, {name: pagePointer, var: page_pointer}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, sort_order: $sort_order, filter: $filter, query: $query, page_pointer: $page_pointer, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Space name exists
#
# GET /spaces/exists/{name}
# operationId: existsSpaceName
export def "exists-space-name" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/spaces/exists/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# flag a space item
#
# PUT /spaces/flag/{itemId}
# operationId: flagSpaceItem
export def "flag-space-item" [
  item_id: string
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
    path: "/spaces/flag/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get flagged items
#
# GET /spaces/flagged
# Returns: record<flaggedItems: table<item: record, parentItem: record>, hasMore: bool, searchPointer: string>
# operationId: getFlaggedItems
export def "get-flagged-items" [
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
  --search-direction: string@search-direction-completer # before or after the time stamp (required, default: BEFORE)
  --timestamp: string # The timestamp according to which you want to retrieve the flagged items (required, format: date-time)
  --search-pointer: string # The searchpointer for the search (initially not set).
  --number-of-results: float # The number of results you want to retrieve. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/flagged"
    query: [{name: searchDirection, var: search_direction, required: true, default: BEFORE}, {name: timestamp, var: timestamp, required: true}, {name: searchPointer, var: search_pointer}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    search_direction: $search_direction, timestamp: $timestamp, search_pointer: $search_pointer, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the spaces by their ids
#
# GET /spaces/ids
# operationId: getSpacesByIds
export def "get-spaces-by-ids" [
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
  --ids: list<string> # an array of ids (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/spaces/ids"
    query: [{name: ids, var: ids, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# deletes a space item
#
# DELETE /spaces/item/{itemId}
# operationId: deleteSpaceItem
export def "delete-space-item" [
  item_id: string
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
    path: "/spaces/item/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like a space item
#
# PUT /spaces/like/{itemId}
# operationId: likeSpaceItem
export def "like-space-item" [
  item_id: string
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
    path: "/spaces/like/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the likes of an item
#
# GET /spaces/likes/{itemId}
# Returns: record<hasMore: bool, participants: table<firstName: string, largeImageUri: string, lastName: string, smallImageUri: string, userId: string>, searchPointer: string>
# operationId: getLikes
export def "get-likes" [
  item_id: string
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
  --search-pointer: string # The searchpointer for the search (initially not set).
  --number-of-results: float # The number of results you want to retrieve. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/likes/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    query: [{name: searchPointer, var: search_pointer}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, search_pointer: $search_pointer, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add recent search
#
# PUT /spaces/search/add/recent
# operationId: addRecentSpaceSearch
export def "add-recent-space-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # The end time. (format: date-time)
  scope: string@scope-completer-1 # The scope of the search.
  search_term: string # The term to search for.
  --start-time: string # The start time. (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/search/add/recent"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: endTime, var: end_time}, {name: scope, var: scope}, {name: searchTerm, var: search_term}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    end_time: $end_time, scope: $scope, search_term: $search_term, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a space search of a client.
#
# PUT /spaces/search/cancel/{searchId}
# operationId: cancelSpaceSearch
export def "cancel-space-search" [
  search_id: string
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
    path: "/spaces/search/cancel/{searchId}"
    path_params: [{name: searchId, var: search_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_id: $search_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve recent space searches
#
# GET /spaces/search/recent
# Returns: table<resList: list<record>>
# operationId: getRecentSearches
export def "get-recent-searches" [
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
    path: "/spaces/search/recent"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# starts a basic search in spaces
#
# GET /spaces/search/startBasic
# Returns: record<spaces: table<accessModeType: string, creationTime: float, creatorId: string, defaultRole: string, description: string, largePictureBase64: string, largePictureContentType: string, largePictureId: string, lastContentCreationTime: float, lastContentCreatorId: string, modificationTime: float, name: string, numberOfExternalParticipants: float, numberOfParticipants: float, numberOfPinnedTopics: float, numberOfReplies: float, numberOfTopics: float, ownerId: string, smallPictureBase64: string, smallPictureContentType: string, smallPictureId: string, spaceId: string, status: string, tags: list, tenantId: string, type: string>, status: string>
# operationId: startBasicSpacesSearch
export def "start-basic-spaces-search" [
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
  --scope: string@scope-completer-1 # the scope of the search (required)
  --search-term: string # the term to search for (required)
  --start-time: string # the starttime (format: date-time)
  --end-time: string # the end time (format: date-time)
  --priority-spaces: list<string> # list of prioritized spaces
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/search/startBasic"
    query: [{name: scope, var: scope, required: true}, {name: searchTerm, var: search_term, required: true}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: prioritySpaces, var: priority_spaces, style: multi}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, search_term: $search_term, start_time: $start_time, end_time: $end_time, priority_spaces: $priority_spaces
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# starts a detailed search in a space
#
# GET /spaces/search/startDetailed
# Returns: table<resList: list<record>>
# operationId: startDetailedSpaceSearch
export def "start-detailed-space-search" [
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
  --scope: string@scope-completer-1 # the scope of the search (required)
  --search-term: string # the term to search for (required)
  --start-time: string # the starttime (format: date-time)
  --end-time: string # the end time (format: date-time)
  --space-id: string # missing documentation (required)
  --search-id: string # missing documentation
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/search/startDetailed"
    query: [{name: scope, var: scope, required: true}, {name: searchTerm, var: search_term, required: true}, {name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: spaceId, var: space_id, required: true}, {name: searchId, var: search_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, search_term: $search_term, start_time: $start_time, end_time: $end_time, space_id: $space_id, search_id: $search_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update tags
#
# PUT /spaces/topic/{topicId}/updateTags
# Returns: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>
# operationId: updateTopicTags
export def "update-topic-tags" [
  topic_id: string
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
  tags: list<string> # The tags to update
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spaces/topic/{topicId}/updateTags"
    path_params: [{name: topicId, var: topic_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: tags, var: tags}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unflag a space item
#
# PUT /spaces/unflag/{itemId}
# operationId: unflagSpaceItem
export def "unflag-space-item" [
  item_id: string
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
    path: "/spaces/unflag/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlike a space item
#
# PUT /spaces/unlike/{itemId}
# operationId: unlikeSpaceItem
export def "unlike-space-item" [
  item_id: string
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
    path: "/spaces/unlike/{itemId}"
    path_params: [{name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a space
#
# DELETE /spaces/{id}
# operationId: deleteSpace
export def "delete-space" [
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
    path: "/spaces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a space
#
# PUT /spaces/{id}
# operationId: updateSpace
export def "update-space" [
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
  --accept: string@accept-completer # Response content type
  --access-mode-type: string@access-mode-type-completer-1 # Access mode (default: NO_CHANGE)
  --description: string # description of the space
  --large-picture-base64: string # large picture
  --name: string # name of the space
  --owner-id: string # ownerid of the space
  --role: string@role-completer-1 # role (default: NO_CHANGE)
  --small-picture-base64: string # small picture
  --status: string@status-completer # status (default: ENABLED)
  --tags: list<string> # tags of the space
  --type: string@type-completer-2 # type (default: NO_CHANGE)
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: accessModeType, var: access_mode_type}, {name: description, var: description}, {name: largePictureBase64, var: large_picture_base64}, {name: name, var: name}, {name: ownerId, var: owner_id}, {name: role, var: role}, {name: smallPictureBase64, var: small_picture_base64}, {name: status, var: status}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, access_mode_type: $access_mode_type, description: $description, large_picture_base64: $large_picture_base64, name: $name, owner_id: $owner_id, role: $role, small_picture_base64: $small_picture_base64, status: $status, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Join a space
#
# POST /spaces/{id}/join
# operationId: joinSpace
export def "join-space" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: post
    path: "/spaces/{id}/join"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign labels
#
# POST /spaces/{id}/labels/assign
# Returns: table<labelIds: list<string>>
# operationId: assignLabels
export def "assign-labels" [
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
  --accept: string@accept-completer # Response content type
  labels: list<string> # The labels to assign to the space
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/labels/assign"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: labels, var: labels}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign labels
#
# DELETE /spaces/{id}/labels/unassign
# Returns: table<labelIds: list<string>>
# operationId: unassignLabels
export def "unassign-labels" [
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
  --accept: string@accept-completer # Response content type
  label_ids: list<string> # missing documentation
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/spaces/{id}/labels/unassign"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: labelIds, var: label_ids}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, label_ids: $label_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Leave a space
#
# POST /spaces/{id}/leave
# operationId: leaveSpace
export def "leave-space" [
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
    path: "/spaces/{id}/leave"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Participant to Space
#
# POST /spaces/{id}/participant
# Returns: list<any>
# operationId: addParticipantsToSpace
export def "add-participants-to-space" [
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
  --accept: string@accept-completer # Response content type
  role: string@role-completer-2 # The name of the role of the participant (default: DEFAULT)
  user_id: list<string> # The user id of the participant
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{id}/participant"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: role, var: role}, {name: userId, var: user_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, role: $role, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes participants from a space
#
# POST /spaces/{id}/participant/remove
# operationId: v2RemoveParticipantsFromSpace
export def "v2-remove-participants-from-space" [
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
  user_ids: list<string> # The ids of the participants to remove
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{id}/participant/remove"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: userIds, var: user_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the participants of a space
#
# GET /spaces/{id}/participants
# Returns: record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string>
# operationId: getSpaceParticipants
export def "get-space-participants" [
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
  --accept: string@accept-completer # Response content type
  --sort-by: string@sort-by-completer-1 # sort the spaces by LAST_CONTENT, NAME, NUMBER_OF_USERS or CREATION_DATE (required, default: NAME)
  --sort-order: string@sort-order-completer # ascending or descending (required, default: ASCENDING)
  --filter-type: string@filter-type-completer # filtertype for participants (ACCESS_TYPE, ROLE or STATE) (required)
  --filter-value: string # value for the filter
  --query: string # some sort of query
  --search-pointer: string # The search pointer (leave empty initially).
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/participants"
    path_params: [{name: id, var: id}]
    query: [{name: sortBy, var: sort_by, required: true, default: NAME}, {name: sortOrder, var: sort_order, required: true, default: ASCENDING}, {name: filterType, var: filter_type, required: true}, {name: filterValue, var: filter_value}, {name: query, var: query}, {name: searchPointer, var: search_pointer}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort_by: $sort_by, sort_order: $sort_order, filter_type: $filter_type, filter_value: $filter_value, query: $query, search_pointer: $search_pointer, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the pending participants of a space
#
# GET /spaces/{id}/participants/pending
# Returns: record<hasMore: bool, participants: table<creationTime: float, firstName: string, lastName: string, modificationTime: float, numberOfReplies: float, numberOfTopics: float, role: string, smallImageUri: string, state: string, tenantId: string, userId: string>, searchPointer: string>
# operationId: getPendingParticipants
export def "get-pending-participants" [
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
  --accept: string@accept-completer # Response content type
  --search-pointer: string # The search pointer (leave empty initially).
  --number-of-results: float # number of results to return, 25 by default. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/participants/pending"
    path_params: [{name: id, var: id}]
    query: [{name: searchPointer, var: search_pointer}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, search_pointer: $search_pointer, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve pinned topics
#
# GET /spaces/{id}/pinnedTopics
# Returns: table<position: float, subject: string, topicId: string>
# operationId: getPinnedTopics
export def "get-pinned-topics" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/pinnedTopics"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Finds participants to add to add to a space
#
# GET /spaces/{id}/searchParticipantsToAdd
# Returns: table<department: string, firstName: string, isMember: bool, jobTitle: string, lastName: string, smallImageUri: string, tenantId: string, userId: string>
# operationId: searchParticipantsToAdd
export def "search-participants-to-add" [
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
  --accept: string@accept-completer # Response content type
  --query: string # The query (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/searchParticipantsToAdd"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the participants of a space
#
# GET /spaces/{id}/searchSpaceParticipants
# Returns: table<hasMore: bool, participants: list<record>, searchPointer: string>
# operationId: searchSpaceParticipants
export def "search-space-participants" [
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
  --accept: string@accept-completer # Response content type
  --query: string # The query to search with. If searchpointer/hasMotre is returned, refine query. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{id}/searchSpaceParticipants"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update read timestamp
#
# PUT /spaces/{id}/updateTimestamp
# operationId: updateReadTimestamp
export def "update-read-timestamp" [
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
  timestamp: string # The new timestamp (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/{id}/updateTimestamp"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update participant
#
# PUT /spaces/{spaceId}/participant
# operationId: updateParticipantInSpace
export def "update-participant-in-space" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string@role-completer # updated role of participant
  user_id: string # The id of the participant to update
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/{spaceId}/participant"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: role, var: role}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, role: $role, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# missing documentation
#
# GET /spaces/{spaceId}/participant/import/
# Returns: record<actualNumberOfImportedParticipants: float, estimatedImportDuration: float, importEndDate: float, importFileId: string, importFileName: string, importProgress: float, importStartDate: float, importStatus: string, plannedNumberOfImportedParticipants: float, resultFileId: string, resultFileName: string>
# operationId: getParticipantsImportData
export def "get-participants-import-data" [
  space_id: string
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
    path: "/spaces/{spaceId}/participant/import/"
    path_params: [{name: spaceId, var: space_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# request access for a space
#
# POST /spaces/{spaceId}/participant/request
# operationId: requestSpaceAcces
export def "request-space-acces" [
  space_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason why the Access has been requested
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/participant/request"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny access for a space
#
# POST /spaces/{spaceId}/participant/{participantId}/deny
# operationId: denySpaceAcces
export def "deny-space-acces" [
  space_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason why the request has been denied
]: any -> any {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/participant/{participantId}/deny"
    path_params: [{name: spaceId, var: space_id}, {name: participantId, var: participant_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, participant_id: $participant_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# grant access for a space
#
# POST /spaces/{spaceId}/participant/{participantId}/grant
# operationId: grantSpaceAcces
export def "grant-space-acces" [
  space_id: string
  participant_id: string
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
    path: "/spaces/{spaceId}/participant/{participantId}/grant"
    path_params: [{name: spaceId, var: space_id}, {name: participantId, var: participant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, participant_id: $participant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new space topic
#
# POST /spaces/{spaceId}/topic
# Returns: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>
# operationId: createSpaceTopic
export def "create-space-topic" [
  space_id: string
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
  --attachments: list<string> # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # The content of this topic
  --content-tags: list<string> # the content tags
  --form-meta-data: string # The formMetaData
  --mentioned-user: string # A list of mentioned users
  subject: string # The subject of the topic
  --tags: list<string> # the tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/topic"
    path_params: [{name: spaceId, var: space_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: complex, var: complex}, {name: content, var: content}, {name: contentTags, var: content_tags}, {name: formMetaData, var: form_meta_data}, {name: mentionedUser, var: mentioned_user}, {name: subject, var: subject}, {name: tags, var: tags}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, attachments: $attachments, complex: $complex, content: $content, content_tags: $content_tags, form_meta_data: $form_meta_data, mentioned_user: $mentioned_user, subject: $subject, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets space replies and a topic
#
# GET /spaces/{spaceId}/topic/{topicId}
# Returns: record<replies: table<parentTopicId: string, spaceItem: record>, topic: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>>>
# operationId: v2GetTopicWithReplies
export def "v2-get-topic-with-replies" [
  space_id: string
  topic_id: string
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
  --number-of-replies: float # The number of replies (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/topic/{topicId}"
    path_params: [{name: spaceId, var: space_id}, {name: topicId, var: topic_id}]
    query: [{name: numberOfReplies, var: number_of_replies}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, topic_id: $topic_id, number_of_replies: $number_of_replies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a topic
#
# PUT /spaces/{spaceId}/topic/{topicId}
# Returns: record<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>, subject: string, tags: list<string>>
# operationId: updateSpaceTopic
export def "update-space-topic" [
  space_id: string
  topic_id: string
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
  --attachments: list<string> # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # content of the topic
  --content-tags: list<string> # the content tags
  --form-meta-data: string # formMetaData to update
  --mentioned-users: list<string> # the updated mentioned users
  --subject: string # the subject of the topic
  --tags: list<string> # the tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spaces/{spaceId}/topic/{topicId}"
    path_params: [{name: spaceId, var: space_id}, {name: topicId, var: topic_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: complex, var: complex}, {name: content, var: content}, {name: contentTags, var: content_tags}, {name: formMetaData, var: form_meta_data}, {name: mentionedUsers, var: mentioned_users}, {name: subject, var: subject}, {name: tags, var: tags}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, topic_id: $topic_id, attachments: $attachments, complex: $complex, content: $content, content_tags: $content_tags, form_meta_data: $form_meta_data, mentioned_users: $mentioned_users, subject: $subject, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets space replies
#
# GET /spaces/{spaceId}/topic/{topicId}/reply
# Returns: record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>
# operationId: getSpaceReplies
export def "get-space-replies" [
  space_id: string
  topic_id: string
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
  --search-direction: string@search-direction-completer # Search before or after a certain timestamp (required, default: BEFORE)
  --timestamp: string # Timestamp to start the search from (format: date-time)
  --number-of-results: float # The number of results that should be returned (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/topic/{topicId}/reply"
    path_params: [{name: spaceId, var: space_id}, {name: topicId, var: topic_id}]
    query: [{name: searchDirection, var: search_direction, required: true, default: BEFORE}, {name: timestamp, var: timestamp}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, topic_id: $topic_id, search_direction: $search_direction, timestamp: $timestamp, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# creates a reply to a topic
#
# POST /spaces/{spaceId}/topic/{topicId}/reply
# Returns: record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>
# operationId: createReply
export def "create-reply" [
  space_id: string
  topic_id: string
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
  --attachments: list<string> # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # Content of the reply
  --form-meta-data: string # formMetaData used in the reply
  --mentioned-user: string # the user mentioned in the reply
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spaces/{spaceId}/topic/{topicId}/reply"
    path_params: [{name: spaceId, var: space_id}, {name: topicId, var: topic_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: complex, var: complex}, {name: content, var: content}, {name: formMetaData, var: form_meta_data}, {name: mentionedUser, var: mentioned_user}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, topic_id: $topic_id, attachments: $attachments, complex: $complex, content: $content, form_meta_data: $form_meta_data, mentioned_user: $mentioned_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a space reply
#
# PUT /spaces/{spaceId}/topic/{topicId}/reply/{replyId}
# Returns: record<parentTopicId: string, spaceItem: record<Status: string, attachments: list<record>, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list<record>, formMetaData: string, itemId: string, mentionedUsers: list<string>, modificationTime: float, numberOfLikes: float, previews: list<record>, sharedItems: list<record>, spaceId: string, tenantId: string>>
# operationId: updateSpaceReply
export def "update-space-reply" [
  space_id: string
  topic_id: string
  reply_id: string
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
  --attachments: list<string> # the attached files
  --complex: oneof<nothing, bool> # complex or not
  --content: string # the content of the reply
  --form-meta-data: string # formMetaData of the reply
  --mentioned-users: list<string> # the mentioned users in the reply
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/spaces/{spaceId}/topic/{topicId}/reply/{replyId}"
    path_params: [{name: spaceId, var: space_id}, {name: topicId, var: topic_id}, {name: replyId, var: reply_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: attachments, var: attachments}, {name: complex, var: complex}, {name: content, var: content}, {name: formMetaData, var: form_meta_data}, {name: mentionedUsers, var: mentioned_users}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, topic_id: $topic_id, reply_id: $reply_id, attachments: $attachments, complex: $complex, content: $content, form_meta_data: $form_meta_data, mentioned_users: $mentioned_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets space topics
#
# GET /spaces/{spaceId}/topics
# Returns: table<lastContentCreationTime: float, lastContentCreatorId: string, numberOfReplies: float, pinned: bool, spaceItem: record<Status: string, attachments: list, complex: bool, content: string, creationTime: float, creatorId: string, deletedBy: string, externalAttachments: list, formMetaData: string, itemId: string, mentionedUsers: list, modificationTime: float, numberOfLikes: float, previews: list, sharedItems: list, spaceId: string, tenantId: string>, subject: string, tags: list<string>>
# operationId: getSpaceTopics
export def "get-space-topics" [
  space_id: string
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
  --search-direction: string@search-direction-completer # Search before or after a certain timestamp (required, default: BEFORE)
  --timestamp: string # Timestamp to start the search from (format: date-time)
  --number-of-results: float # The number of results that should be returned (format: int32, default: 25)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spaces/{spaceId}/topics"
    path_params: [{name: spaceId, var: space_id}]
    query: [{name: searchDirection, var: search_direction, required: true, default: BEFORE}, {name: timestamp, var: timestamp}, {name: numberOfResults, var: number_of_results}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, search_direction: $search_direction, timestamp: $timestamp, number_of_results: $number_of_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update content of welcome box
#
# PUT /spaces/{spaceId}/welcomebox/{content}
# operationId: v2UpdateWelcomeBoxContent
export def "v2-update-welcome-box-content" [
  space_id: string
  content: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-welcome-box: oneof<nothing, bool> # True, false, default:false (default: false)
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/{spaceId}/welcomebox/{content}"
    path_params: [{name: spaceId, var: space_id}, {name: content, var: content}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: displayWelcomeBox, var: display_welcome_box}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    space_id: $space_id, content: $content, display_welcome_box: $display_welcome_box
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pin a topic
#
# PUT /spaces/{topicId}/pin
# operationId: pinTopic
export def "pin-topic" [
  topic_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  position: float # The position to pin to (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/spaces/{topicId}/pin"
    path_params: [{name: topicId, var: topic_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpin a topic
#
# PUT /spaces/{topicId}/unpin
# operationId: unpinTopic
export def "unpin-topic" [
  topic_id: string
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
    path: "/spaces/{topicId}/unpin"
    path_params: [{name: topicId, var: topic_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get devices infos
#
# GET /telephony/deviceInfos
# Returns: table<clientId: string, clientVersion: string, deviceSubtype: string, deviceType: string, hardwareModel: string, homeNode: string, manufacturer: string, osVersion: string, userId: string>
# operationId: v2GetDeviceInfos
export def "v2-get-device-infos" [
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
    path: "/telephony/deviceInfos"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get telephony conversation id
#
# GET /telephony/telephonyConversationId
# operationId: v2GetTelephonyConversationId
export def "v2-get-telephony-conversation-id" [
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
    path: "/telephony/telephonyConversationId"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get journal
#
# GET /telephony/{telephonyConversationId}/journal
# Returns: table<attachments: list<record>, convId: string, creationTime: float, creatorId: string, includeInUnreadCount: bool, itemId: string, modificationTime: float, rtc: record<ended: record, missed: string, moved: record, rtcParticipants: list, type: string>, system: record<affectedParticipants: list, newTopic: string, oldTopic: string, type: string>, text: record<content: string, contentType: string, formMetaData: string, isWebhookMessage: bool, likedUserIds: list, parentId: string, preview: record, state: string, subject: string>, type: string>
# operationId: getJournalEntries
export def "get-journal-entries" [
  telephony_conversation_id: string
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
  --timestamp: float # A timestamp, default = 0 (format: int64, default: 0)
  --number-of-entries: float # The number of entries, between 1 and 100, default = 25 (format: int32, default: 25)
  --direction: string@direction-completer-1 # The direction (BEFORE||AFTER||BOTH), default = AFTER (default: AFTER)
  --journal-filter: string@journal-filter-completer # The filter, ALL||MISSED||DIALED||RECEIVED||DIVERTED||VOICEMAILS||UNHERAD_VOICEMAILS. default = ALL (default: ALL)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/telephony/{telephonyConversationId}/journal"
    path_params: [{name: telephonyConversationId, var: telephony_conversation_id}]
    query: [{name: timestamp, var: timestamp}, {name: numberOfEntries, var: number_of_entries}, {name: direction, var: direction}, {name: journalFilter, var: journal_filter}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    telephony_conversation_id: $telephony_conversation_id, timestamp: $timestamp, number_of_entries: $number_of_entries, direction: $direction, journal_filter: $journal_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for users
#
# GET /users
# Returns: table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: searchUser
export def "search-user" [
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
  --name: string # Search for a user by name (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: name, var: name, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all user labels
#
# GET /users/labels
# Returns: table<labelId: string, value: string>
# operationId: getLabel
export def "get-label" [
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
    path: "/users/labels"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user label
#
# POST /users/labels
# Returns: record<labelId: string, value: string>
# operationId: addLabel
export def "add-label" [
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
  label: string # The label value to add
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/labels"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: label, var: label}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a user label
#
# DELETE /users/labels/{labelId}
# Returns: record<labelId: string, value: string>
# operationId: removeLabel
export def "remove-label" [
  label_id: string
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
    path: "/users/labels/{labelId}"
    path_params: [{name: labelId, var: label_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search multiple users.
#
# GET /users/list
# Returns: table<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: list<record>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: list<record>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: searchUsersList
export def "search-users-list" [
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
  --name: list<string> # Multiple email addresses or UUIDs. (required)
  --return-full-user-info: oneof<nothing, bool> # Boolean, return full user info? (default: false)
  --secondary-lookup: oneof<nothing, bool> # Boolean, lookup secondary email? (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/list"
    query: [{name: name, var: name, style: multi, required: true}, {name: returnFullUserInfo, var: return_full_user_info}, {name: secondaryLookup, var: secondary_lookup}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, return_full_user_info: $return_full_user_info, secondary_lookup: $secondary_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the presence status
#
# GET /users/presence
# Returns: table<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>
# operationId: getPresence
export def "get-presence" [
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
  --user-ids: list<string> # A list of unique user IDs or email addresses of the users you want to query the presence state for (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/presence"
    query: [{name: userIds, var: user_ids, style: multi, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the presence status
#
# PUT /users/presence
# Returns: record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>
# operationId: setUserPresence
export def "set-user-presence" [
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
  --clear-dnd: oneof<nothing, bool> # Clear the DND of the user. (default: false)
  --dnd-until: string # Timestamp until the DND state of the user is active. This field is mandatory when the state is set to DND. (format: date-time)
  state: string # The user's presence.
  --status-message: string # An optional status message that is displayed instead of the location
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/presence"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: clearDND, var: clear_dnd}, {name: dndUntil, var: dnd_until}, {name: state, var: state}, {name: statusMessage, var: status_message}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    clear_dnd: $clear_dnd, dnd_until: $dnd_until, state: $state, status_message: $status_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the authenticated user's profile information
#
# GET /users/profile
# Returns: record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: getProfile
export def "get-profile" [
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
    path: "/users/profile"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the user profile
#
# PUT /users/profile
# Returns: record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: updateProfile
export def "update-profile" [
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
  --firstname: string # The new firstname of the user
  --job-title: string # The new job title of the user
  --lastname: string # The new lastname of the user
  --locale: string@locale-completer # The new locale of the user. One of EN_US, DE_DE, EN_GB, ES_ES, FR_FR, IT_IT, RU_RU, ZH_HANS_CN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/profile"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: firstname, var: firstname}, {name: jobTitle, var: job_title}, {name: lastname, var: lastname}, {name: locale, var: locale}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    firstname: $firstname, job_title: $job_title, lastname: $lastname, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the support information
#
# GET /users/supportinfo
# Returns: record<supportEmailAddress: string, supportType: any>
# operationId: getSupportInfo
export def "get-support-info" [
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
    path: "/users/supportinfo"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user by email
#
# GET /users/{emailAddress}/getUserByEmail
# Returns: record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: getUserByEmailAddress
export def "get-user-by-email-address" [
  email_address: string
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
  --secondary-lookup: oneof<nothing, bool> # secondaryLookup enabled (default = false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{emailAddress}/getUserByEmail"
    path_params: [{name: emailAddress, var: email_address}]
    query: [{name: secondaryLookup, var: secondary_lookup}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    email_address: $email_address, secondary_lookup: $secondary_lookup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the user's profile information
#
# GET /users/{id}
# Returns: record<avatar: string, avatarLarge: string, company: string, department: string, displayName: string, emailAddress: string, emailAddresses: table<address: string, type: string>, firstName: string, jobTitle: string, lastName: string, locale: string, phoneNumber: string, phoneNumbers: table<phoneNumber: string, type: string>, primaryTenantId: string, secondaryEmailAddress: string, secondaryTenantId: string, userId: string, userState: string, userType: string>
# operationId: getUserById
export def "get-user-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the presence status
#
# GET /users/{id}/presence
# Returns: record<dndUntil: float, isOptedOut: bool, latitude: float, locationText: string, longitude: float, mobile: bool, poor: bool, state: string, statusMessage: string, timeZoneOffset: float, userId: string>
# operationId: getUserPresence
export def "get-user-presence" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id}/presence"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes all webHooks
#
# DELETE /webhooks
# operationId: removeWebHooks
export def "remove-web-hooks" [
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
    path: "/webhooks"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of webHooks
#
# GET /webhooks
# Returns: table<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: getWebHook
export def "get-web-hook" [
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
    path: "/webhooks"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a WebHook
#
# POST /webhooks
# Returns: record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: addWebHook
export def "add-web-hook" [
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
  filter: list<string> # A filter for WebHooks that checks for a list of configured events. This filter will use a regular expression to determine if it is interested in the events or not. The event itself is converted into a string of format AREA.EVENT. Examples: CONVERSATION.CREATE / USER.UPDATE
  url: string # WebHook callback URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: filter, var: filter}, {name: url, var: url}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    filter: $filter, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new webhook for existing conversation.
#
# POST /webhooks/incoming/create/{conversationId}
# Returns: record<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string>
# operationId: createIncomingWebhook
export def "create-incoming-webhook" [
  conversation_id: string
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
  --name: string # The name of the webhook
  --user-id: string # The id of the user of the webhook
  --description: string # A short description of the webhook
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/incoming/create/{conversationId}"
    path_params: [{name: conversationId, var: conversation_id}]
    query: [{name: name, var: name}, {name: userId, var: user_id}, {name: description, var: description}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, name: $name, user_id: $user_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all webhooks of a special user.
#
# GET /webhooks/incoming/user/{userId}
# Returns: table<conversationId: string, creationTime: float, creatorId: string, description: string, modificationTime: float, name: string, status: string, tenantId: string, url: string, userId: string, webhookId: string>
# operationId: getIncomingWebhookByUser
export def "get-incoming-webhook-by-user" [
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
  --accept: string@accept-completer # Response content type
  --pagesize: float # Max number of hooks per request. Default is 25 (format: int32, default: 25)
  --searchpointer: string # Start of search if consequtive call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/incoming/user/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: pagesize, var: pagesize}, {name: searchpointer, var: searchpointer}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, pagesize: $pagesize, searchpointer: $searchpointer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing webhook
#
# DELETE /webhooks/incoming/{webhookId}
# operationId: deleteIncomingWebhook
export def "delete-incoming-webhook" [
  webhook_id: string
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
    path: "/webhooks/incoming/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post text item for conversation via webhook.
#
# POST /webhooks/incoming/{webhookId}
# operationId: postWebhookAsSlackMessage
export def "post-webhook-as-slack-message" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-url: string # missing documentation
  --filename: string # missing documentation
  --markdown: oneof<nothing, bool> # missing documentation
  --subject: string # missing documentation
  --text: string # The text which will occur in the conversation. May contain formats like *bold* or _italic_
]: any -> any {
  $in | http-request {
    method: post
    path: "/webhooks/incoming/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: fileURL, var: file_url}, {name: filename, var: filename}, {name: markdown, var: markdown}, {name: subject, var: subject}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, file_url: $file_url, filename: $filename, markdown: $markdown, subject: $subject, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers Presence WebHook registration
#
# POST /webhooks/presence
# Returns: record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: addPresenceWebHook
export def "add-presence-web-hook" [
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
  url: string # WebHook callback URL
  user_ids: list<string> # The IDs of the users to subscribe for their presence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/presence"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: userIds, var: user_ids}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    url: $url, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a Presence WebHook registration
#
# PUT /webhooks/presence/{id}
# Returns: record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: updatePresenceWebHook
export def "update-presence-web-hook" [
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
  --accept: string@accept-completer # Response content type
  --url: string # WebHook callback URL
  --user-ids: list<string> # The IDs of the users to subscribe for their presence
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/presence/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: userIds, var: user_ids}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, url: $url, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes a registered webHook
#
# DELETE /webhooks/{id}
# operationId: removeWebHook
export def "remove-web-hook" [
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
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a webHook
#
# GET /webhooks/{id}
# Returns: record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: getWebHookById
export def "get-web-hook-by-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a WebHook registration
#
# PUT /webhooks/{id}
# Returns: record<creationTime: float, filter: list<string>, id: string, subscriptionIds: list<string>, type: string, url: string, userId: string>
# operationId: updateWebHook
export def "update-web-hook" [
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
  --accept: string@accept-completer # Response content type
  --filter: list<string> # A filter for WebHooks that checks for a list of configured events. This filter will use a regular expression to determine if it is interested in the events or not. The event itself is converted into a string of format AREA.EVENT. Examples: CONVERSATION.CREATE / USER.UPDATE
  --url: string # WebHook callback URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: filter, var: filter}, {name: url, var: url}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter: $filter, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
