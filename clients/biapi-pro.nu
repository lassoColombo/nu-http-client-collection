# Auto-generated client for Budgea API Documentation v2.0
# Source: https://api.apis.guru/v2/specs/biapi.pro/2.0/openapi.json
# Auth: --token flag or $env.BUDGEA_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "http://localhost//budgea.biapi.pro/2.0"
  token_env_var: "BUDGEA_API_DOCUMENTATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["http://localhost//budgea.biapi.pro/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "jwt_token" "payload"] }
def accept-completer-1 [] { ["application/json" "auth_token" "expires_in" "type"] }
def accept-completer-2 [] { ["access_token" "application/json" "token_type"] }
def accept-completer-3 [] { ["application/json" "profile" "scope" "token" "user"] }
def accept-completer-4 [] { ["access" "application/json" "code" "expires_in" "type"] }
def accept-completer-5 [] { ["application/json" "failed" "total" "transactions"] }
def accept-completer-6 [] { ["application/json" "auth_mechanism" "beta" "capabilities" "categories" "charged" "code" "color" "hidden" "id" "name" "slug" "sync_frequency"] }
def accept-completer-7 [] { ["application/json" "biapi.last_push"] }
def accept-completer-8 [] { ["application/json" "compagny" "owner"] }
def accept-completer-9 [] { ["application/json" "token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account-types: "record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float>"
    get-account-types-id-account-type: "record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>"
    post-admin-jwt: "record"
    post-auth-init: "record<auth_token: string, expires_in: int, type: string>"
    post-auth-jwt: "record<jwt_token: string, payload: record>"
    post-auth-renew: "record<access_token: string, token_type: string>"
    post-auth-token: "record<expires_in: int, scope: string, token: string>"
    post-auth-token-access: "record<access_token: string, token_type: string>"
    get-auth-token-code: "record<access: string, code: string, expires_in: int, type: record>"
    get-banks: "record<banks: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>"
    post-banks-categories: "record<id: int, name: string>"
    delete-banks-categories-id-category: "record<id: int, name: string>"
    post-banks-categories-id-category: "record<id: int, name: string>"
    get-banks-id-bank: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    get-banks-id-connector-connections: "record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>"
    get-banks-id-connector-logos: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-banks-id-connector-logos-main: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-banks-id-connector-logos-thumbnail: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-banks-id-connector-sources: "record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>"
    get-banks-id-connector-sources-id-connector-source-fields: "record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>"
    get-banks-id-connector-sources-id-source: "record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>"
    get-categories: "record<categories: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float>"
    post-categories-keywords: "record<id: int, id_category: int, income: bool, keyword: string, priority: int>"
    delete-categories-keywords-id-keyword: "record<id: int, id_category: int, income: bool, keyword: string, priority: int>"
    post-categorize: "record"
    get-certificate-type: "record<created: string, id: int, id_private_key_file: int, id_public_key_file: int, type: string>"
    get-clients: "record<clients: table<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>, total: float>"
    post-clients: "record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>"
    delete-clients-id-client: "record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>"
    get-clients-id-client: "record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>"
    put-clients-id-client: "record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>"
    delete-clients-id-client-logo: "record<content_type: string, file_size: int, filename: string, id: int>"
    post-clients-id-client-logo: "record<content_type: string, file_size: int, filename: string, id: int>"
    get-config-logs: "record<configlogs: table<id: int, key: string, new_value: string, origin: string, previous_value: string, timestamp: string, type: string>, total: float>"
    get-connections: "record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>"
    get-connections-id-connection-logs: "record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>"
    get-connections-id-connection-sources: "record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>"
    delete-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    post-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    put-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    get-connectors: "record<connectors: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>"
    post-connectors: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    put-connectors: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    get-connectors-id-connector: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    put-connectors-id-connector: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    get-connectors-id-connector-logos: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    post-connectors-id-connector-logos: "record<id: int, id_connector: int, id_file: int, type: string>"
    put-connectors-id-connector-logos: "record<id: int, id_connector: int, id_file: int, type: string>"
    get-connectors-id-connector-logos-main: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-connectors-id-connector-logos-thumbnail: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    delete-connectors-id-connector-logos-id-logo: "record<id: int, id_connector: int, id_file: int, type: string>"
    put-connectors-id-connector-logos-id-logo: "record<id: int, id_connector: int, id_file: int, type: string>"
    get-connectors-id-connector-sources: "record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>"
    put-connectors-id-connector-sources: "record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>"
    get-connectors-id-connector-sources-id-connector-source-fields: "record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>"
    get-connectors-id-connector-sources-id-source: "record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>"
    put-connectors-id-connector-sources-id-source: "record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>"
    get-logs: "record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>"
    get-providers: "record<providers: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>"
    get-providers-id-connector-connections: "record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>"
    get-providers-id-connector-logos: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-providers-id-connector-logos-main: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-providers-id-connector-logos-thumbnail: "record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>"
    get-providers-id-connector-sources: "record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>"
    get-providers-id-connector-sources-id-connector-source-fields: "record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>"
    get-providers-id-connector-sources-id-source: "record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>"
    get-providers-id-provider: "record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>"
    get-psd2-registrations: "record<psd2registrations: table<id: int, id_connector_source: int, status: string>, total: float>"
    get-psd2-registrations-id-psd2-registration: "record<id: int, id_connector_source: int, status: string>"
    get-psd2-registrations-id-psd2registration-logs: "record<psd2registrationlogs: table<created_at: string, error_message: string, id: int, id_psd2registration: int, type: string>, total: float>"
    get-users: "record<total: float, users: table<id: int, platform: string, signin: string>>"
    delete-users-id-user: "record<id: int, platform: string, signin: string>"
    get-users-id-user: "record<id: int, platform: string, signin: string>"
    get-users-id-user-account-types: "record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float>"
    get-users-id-user-account-types-id-account-type: "record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>"
    get-users-id-user-accounts-id-account-transactionsclusters: "record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>"
    post-users-id-user-accounts-id-account-transactionsclusters: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    delete-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    put-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    get-users-id-user-alerts: "record<alerts: table<id: int, id_account: int, id_investment: int, id_transaction: int, id_user: int, timestamp: string, type: string, value: float>, total: float>"
    get-users-id-user-categories-full: "record<categorys: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float>"
    post-users-id-user-categories-full: "record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>"
    delete-users-id-user-categories-full-id-full: "record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>"
    put-users-id-user-categories-full-id-full: "record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>"
    get-users-id-user-config: "record"
    delete-users-id-user-connections: "record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>"
    get-users-id-user-connections: "record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>"
    post-users-id-user-connections: "record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>"
    delete-users-id-user-connections-id-connection: "record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>"
    post-users-id-user-connections-id-connection: "record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>"
    put-users-id-user-connections-id-connection: "record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>"
    delete-users-id-user-connections-id-connection-accounts: "record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>"
    get-users-id-user-connections-id-connection-accounts: "record<accounts: table<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>, total: float>"
    post-users-id-user-connections-id-connection-accounts: "record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>"
    put-users-id-user-connections-id-connection-accounts: "record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>"
    delete-users-id-user-connections-id-connection-accounts-id-account: "record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>"
    put-users-id-user-connections-id-connection-accounts-id-account: "record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>"
    get-users-id-user-connections-id-connection-accounts-id-account-logs: "record<accountlogs: table<balance: float, coming: float, error: string, error_message: string, id: int, id_account: int, id_connection_log: int, id_connector: int, timestamp: string>, total: float>"
    get-users-id-user-connections-id-connection-accounts-id-account-sources: "record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>"
    delete-users-id-user-connections-id-connection-accounts-id-account-transactions: "record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>"
    get-users-id-user-connections-id-connection-accounts-id-account-transactions: "record<total: float, transactions: table<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>>"
    post-users-id-user-connections-id-connection-accounts-id-account-transactions: "record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>"
    put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction: "record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>"
    delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations: "record<id: int, id_transaction: int, key: string, value: string>"
    get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations: "record<total: float, transactioninformations: table<id: int, id_transaction: int, key: string, value: string>>"
    put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations: "record<id: int, id_transaction: int, key: string, value: string>"
    delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information: "record<id: int, id_transaction: int, key: string, value: string>"
    get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information: "record<id: int, id_transaction: int, key: string, value: string>"
    get-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters: "record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>"
    post-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    delete-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    put-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    get-users-id-user-connections-id-connection-informations: "record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>"
    get-users-id-user-connections-id-connection-logs: "record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>"
    get-users-id-user-connections-id-connection-sources: "record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>"
    delete-users-id-user-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    post-users-id-user-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    put-users-id-user-connections-id-connection-sources-id-source: "record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>"
    get-users-id-user-connections-id-connection-transactionsclusters: "record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>"
    post-users-id-user-connections-id-connection-transactionsclusters: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    delete-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    put-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    get-users-id-user-logs: "record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>"
    get-users-id-user-profiles: "record<profiles: table<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>, total: float>"
    get-users-id-user-profiles-main: "record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>"
    get-users-id-user-profiles-id-profile: "record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>"
    post-users-id-user-token: "record"
    get-users-id-user-transactionsclusters: "record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>"
    post-users-id-user-transactionsclusters: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    delete-users-id-user-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    put-users-id-user-transactionsclusters-id-transactionscluster: "record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>"
    delete-webhooks: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    get-webhooks: "record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>>"
    post-webhooks: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    delete-webhooks-auth: "record<id: int, name: string, type: string>"
    get-webhooks-auth: "record<authproviders: table<id: int, name: string, type: string>, total: float>"
    post-webhooks-auth: "record<id: int, name: string, type: string>"
    delete-webhooks-auth-id-auth: "record<id: int, name: string, type: string>"
    post-webhooks-auth-id-auth: "record<id: int, name: string, type: string>"
    put-webhooks-auth-id-auth: "record<id: int, name: string, type: string>"
    delete-webhooks-id-webhook: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    post-webhooks-id-webhook: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    put-webhooks-id-webhook: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    delete-webhooks-id-webhook-add-to-data: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    get-webhooks-id-webhook-add-to-data: "record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>>"
    post-webhooks-id-webhook-add-to-data: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    delete-webhooks-id-webhook-add-to-data-key: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    get-webhooks-id-webhook-add-to-data-key: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    post-webhooks-id-webhook-add-to-data-key: "record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>"
    get-webhooks-id-webhook-logs: "record<total: float, webhooklogs: table<id: int, id_service: int, id_user: int, id_webhook_data: int, next_try: string, response_code: int, response_date: string, timestamp: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account-types" "get-account-types-id-account-type" "post-admin-jwt" "post-auth-init" "post-auth-jwt" "post-auth-renew" "delete-auth-token" "post-auth-token" "post-auth-token-access" "get-auth-token-code" "get-banks" "post-banks-categories" "delete-banks-categories-id-category" "post-banks-categories-id-category" "get-banks-id-bank" "get-banks-id-connector-connections" "get-banks-id-connector-logos" "get-banks-id-connector-logos-main" "get-banks-id-connector-logos-thumbnail" "get-banks-id-connector-sources" "get-banks-id-connector-sources-id-connector-source-fields" "get-banks-id-connector-sources-id-source" "get-categories" "post-categories-keywords" "delete-categories-keywords-id-keyword" "post-categorize" "get-certificate-type" "get-clients" "post-clients" "delete-clients-id-client" "get-clients-id-client" "put-clients-id-client" "delete-clients-id-client-logo" "post-clients-id-client-logo" "get-config" "post-config" "get-config-logs" "get-connections" "get-connections-id-connection-logs" "get-connections-id-connection-sources" "delete-connections-id-connection-sources-id-source" "post-connections-id-connection-sources-id-source" "put-connections-id-connection-sources-id-source" "get-connectors" "post-connectors" "put-connectors" "get-connectors-id-connector" "put-connectors-id-connector" "get-connectors-id-connector-logos" "post-connectors-id-connector-logos" "put-connectors-id-connector-logos" "get-connectors-id-connector-logos-main" "get-connectors-id-connector-logos-thumbnail" "delete-connectors-id-connector-logos-id-logo" "put-connectors-id-connector-logos-id-logo" "get-connectors-id-connector-sources" "put-connectors-id-connector-sources" "get-connectors-id-connector-sources-id-connector-source-fields" "get-connectors-id-connector-sources-id-source" "put-connectors-id-connector-sources-id-source" "get-incidents" "get-invoicing" "get-logs" "get-monitoring" "get-providers" "get-providers-id-connector-connections" "get-providers-id-connector-logos" "get-providers-id-connector-logos-main" "get-providers-id-connector-logos-thumbnail" "get-providers-id-connector-sources" "get-providers-id-connector-sources-id-connector-source-fields" "get-providers-id-connector-sources-id-source" "get-providers-id-provider" "get-psd2-registrations" "get-psd2-registrations-id-psd2-registration" "get-psd2-registrations-id-psd2registration-logs" "get-publickey" "post-test-sync" "post-test-webhooks" "get-users" "delete-users-id-user" "get-users-id-user" "get-users-id-user-account-types" "get-users-id-user-account-types-id-account-type" "get-users-id-user-accounts-id-account-categories" "get-users-id-user-accounts-id-account-transactionsclusters" "post-users-id-user-accounts-id-account-transactionsclusters" "delete-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster" "put-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster" "get-users-id-user-alerts" "get-users-id-user-categories" "get-users-id-user-categories-full" "post-users-id-user-categories-full" "delete-users-id-user-categories-full-id-full" "put-users-id-user-categories-full-id-full" "delete-users-id-user-config" "get-users-id-user-config" "post-users-id-user-config" "delete-users-id-user-connections" "get-users-id-user-connections" "post-users-id-user-connections" "delete-users-id-user-connections-id-connection" "post-users-id-user-connections-id-connection" "put-users-id-user-connections-id-connection" "delete-users-id-user-connections-id-connection-accounts" "get-users-id-user-connections-id-connection-accounts" "post-users-id-user-connections-id-connection-accounts" "put-users-id-user-connections-id-connection-accounts" "delete-users-id-user-connections-id-connection-accounts-id-account" "put-users-id-user-connections-id-connection-accounts-id-account" "get-users-id-user-connections-id-connection-accounts-id-account-categories" "get-users-id-user-connections-id-connection-accounts-id-account-delta" "get-users-id-user-connections-id-connection-accounts-id-account-logs" "get-users-id-user-connections-id-connection-accounts-id-account-sources" "delete-users-id-user-connections-id-connection-accounts-id-account-transactions" "get-users-id-user-connections-id-connection-accounts-id-account-transactions" "post-users-id-user-connections-id-connection-accounts-id-account-transactions" "put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction" "delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" "get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" "put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" "delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information" "get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information" "get-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters" "post-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters" "delete-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster" "put-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster" "get-users-id-user-connections-id-connection-informations" "get-users-id-user-connections-id-connection-logs" "get-users-id-user-connections-id-connection-sources" "delete-users-id-user-connections-id-connection-sources-id-source" "post-users-id-user-connections-id-connection-sources-id-source" "put-users-id-user-connections-id-connection-sources-id-source" "get-users-id-user-connections-id-connection-transactionsclusters" "post-users-id-user-connections-id-connection-transactionsclusters" "delete-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster" "put-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster" "get-users-id-user-forecast" "get-users-id-user-logs" "get-users-id-user-profiles" "get-users-id-user-profiles-main" "get-users-id-user-profiles-id-profile" "post-users-id-user-token" "get-users-id-user-transactionsclusters" "post-users-id-user-transactionsclusters" "delete-users-id-user-transactionsclusters-id-transactionscluster" "put-users-id-user-transactionsclusters-id-transactionscluster" "get-webauth" "delete-webhooks" "get-webhooks" "post-webhooks" "delete-webhooks-auth" "get-webhooks-auth" "post-webhooks-auth" "delete-webhooks-auth-id-auth" "post-webhooks-auth-id-auth" "put-webhooks-auth-id-auth" "delete-webhooks-id-webhook" "post-webhooks-id-webhook" "put-webhooks-id-webhook" "delete-webhooks-id-webhook-add-to-data" "get-webhooks-id-webhook-add-to-data" "post-webhooks-id-webhook-add-to-data" "delete-webhooks-id-webhook-add-to-data-key" "get-webhooks-id-webhook-add-to-data-key" "post-webhooks-id-webhook-add-to-data-key" "get-webhooks-id-webhook-logs" "commands"] | sort) } | get name | first)
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

# Get account types
#
# GET /account_types
# Returns: record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float>
export def "get-account-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account_types"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an account type
#
# GET /account_types/{id_account_type}
# Returns: record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>
export def "get-account-types-id-account-type" [
  id_account_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account_types/{id_account_type}"
    path_params: [{name: id_account_type, var: id_account_type}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_account_type: $id_account_type, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a jwt manage token
#
# POST /admin/jwt
# Returns: record
export def "post-admin-jwt" [
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
  --duration: int # number of minute before the token expiration (0 for token that won't expire unless the client application is deleted) (default: 1)
  --scope: string # scope requested for the token (default: config)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/jwt"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: duration, var: duration}, {name: scope, var: scope}]}
    accept: ["application/json", jwt_token, payload]
    ok: [200]
    auth: bearer
  } {
    duration: $duration, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new anonymous user
#
# POST /auth/init
# Returns: record<auth_token: string, expires_in: int, type: string>
export def "post-auth-init" [
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
  --client-id: string # ID of the client
  --client-secret: string # secret of the client
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/init"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}]}
    accept: ["application/json", auth_token, expires_in, type]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a user jwt token
#
# POST /auth/jwt
# Returns: record<jwt_token: string, payload: record>
export def "post-auth-jwt" [
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
  --client-id: string # id of the client
  --client-secret: string # secret for the client
  --expire: oneof<nothing, bool> # if set to True, the token will expire n minutes after its creation, n being the value of configuration key auth.default_token_expire (default: True)
  --id-user: int # user for whom the token has to be generated. If not supplied, a user will be created
  --scope: string # scope requested for the token
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/jwt"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: expire, var: expire}, {name: id_user, var: id_user}, {name: scope, var: scope}]}
    accept: ["application/json", jwt_token, payload]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, expire: $expire, id_user: $id_user, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a new access token given an user id and client credentials
#
# POST /auth/renew
# Returns: record<access_token: string, token_type: string>
export def "post-auth-renew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  client_id: string # ID of the client
  client_secret: string # secret of the client
  --grant-type: string # default is "client_credentials"
  id_user: int # id of the user to generate a token for
  --revoke-previous: oneof<nothing, bool> # if true, all other permanent tokens for the user will be deleted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/renew"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: grant_type, var: grant_type}, {name: id_user, var: id_user}, {name: revoke_previous, var: revoke_previous}]}
    accept: [access_token, "application/json", token_type]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, id_user: $id_user, revoke_previous: $revoke_previous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove user access
#
# DELETE /auth/token
export def "delete-auth-token" [
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
    path: "/auth/token"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login to API with credentials
#
# POST /auth/token
# Returns: record<expires_in: int, scope: string, token: string>
export def "post-auth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
  application: string # application name
  --grant-type: string # password when requesting a user token and client_credentials for a payment manage token (default: password)
  password: string # password
  --scope: string # scope requested for the token
  username: string # username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/token"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: application, var: application}, {name: grant_type, var: grant_type}, {name: password, var: password}, {name: scope, var: scope}, {name: username, var: username}]}
    accept: ["application/json", profile, scope, token, user]
    ok: [200]
    auth: bearer
  } {
    application: $application, grant_type: $grant_type, password: $password, scope: $scope, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Transform a temporary code to a access_token
#
# POST /auth/token/access
# Returns: record<access_token: string, token_type: string>
export def "post-auth-token-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  client_id: string # ID of the client
  client_secret: string # secret of the client
  code: string # user's temporary code
  --grant-type: string # default is "authorization_code"
  --redirect-uri: string # redirect uri used by user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/token/access"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}, {name: grant_type, var: grant_type}, {name: redirect_uri, var: redirect_uri}]}
    accept: [access_token, "application/json", token_type]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code, grant_type: $grant_type, redirect_uri: $redirect_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a user temporary token
#
# GET /auth/token/code
# Returns: record<access: string, code: string, expires_in: int, type: record>
export def "get-auth-token-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-4 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/auth/token/code"
    accept: [access, "application/json", code, expires_in, type]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get list of connectors
#
# GET /banks
# Returns: record<banks: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>
export def "get-banks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bank categories
#
# POST /banks/categories
# Returns: record<id: int, name: string>
export def "post-banks-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  name: string # name of the category to be created
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/banks/categories"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the supplied category
#
# DELETE /banks/categories/{id_category}
# Returns: record<id: int, name: string>
export def "delete-banks-categories-id-category" [
  id_category: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/banks/categories/{id_category}"
    path_params: [{name: id_category, var: id_category}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_category: $id_category, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a bank categories
#
# POST /banks/categories/{id_category}
# Returns: record<id: int, name: string>
export def "post-banks-categories-id-category" [
  id_category: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  name: string # new name for the supplied category
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/banks/categories/{id_category}"
    path_params: [{name: id_category, var: id_category}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_category: $id_category, expand: $expand, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connector
#
# GET /banks/{id_bank}
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "get-banks-id-bank" [
  id_bank: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_bank}"
    path_params: [{name: id_bank, var: id_bank}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_bank: $id_bank, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a subset of id_connection for a given bank. Different selection methode are possible
#
# GET /banks/{id_connector}/connections
# Returns: record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>
export def "get-banks-id-connector-connections" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string # methode of selection use between 'diversity' (default), 'cover' and 'type_select'
  --n: int # the number of requested connections, if applicable by the method
  --type: int # for 'type_select' method. Specific account type id (weboob_type_id) to select
  --occurences: int # for 'type_select' method. Each connection requires at least N
  --source: string # specify a source name that should have a null state
  --minutes-without-sync: int # Ensure the connection will not have a sync happening for at
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/connections"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: method, var: method}, {name: n, var: n}, {name: type, var: type}, {name: occurences, var: occurences}, {name: source, var: source}, {name: minutes_without_sync, var: minutes_without_sync}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, method: $method, n: $n, type: $type, occurences: $occurences, source: $source, minutes_without_sync: $minutes_without_sync, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-banks-id-connector-logos" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/logos"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos/main
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-banks-id-connector-logos-main" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/logos/main"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /banks/{id_connector}/logos/thumbnail
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-banks-id-connector-logos-thumbnail" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/logos/thumbnail"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of connector sources
#
# GET /banks/{id_connector}/sources
# Returns: record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>
export def "get-banks-id-connector-sources" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/sources"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fields specific to a domain and a source
#
# GET /banks/{id_connector}/sources/{id_connector_source}/fields
# Returns: record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>
export def "get-banks-id-connector-sources-id-connector-source-fields" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/sources/{id_connector_source}/fields"
    path_params: [{name: id_connector, var: id_connector}, {name: id_connector_source, var: id_connector_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_connector_source: $id_connector_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the connector source
#
# GET /banks/{id_connector}/sources/{id_source}
# Returns: record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>
export def "get-banks-id-connector-sources-id-source" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/banks/{id_connector}/sources/{id_source}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_source: $id_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all categories
#
# GET /categories
# Returns: record<categories: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float>
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new keyword associated with a category in the database.
#
# POST /categories/keywords
# Returns: record<id: int, id_category: int, income: bool, keyword: string, priority: int>
export def "post-categories-keywords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/categories/keywords"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a particular key-value pair on a transaction.
#
# DELETE /categories/keywords/{id_keyword}
# Returns: record<id: int, id_category: int, income: bool, keyword: string, priority: int>
export def "delete-categories-keywords-id-keyword" [
  id_keyword: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/categories/keywords/{id_keyword}"
    path_params: [{name: id_keyword, var: id_keyword}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_keyword: $id_keyword, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# categorize transactions without storing them
#
# POST /categorize
# Returns: record
export def "post-categorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-5 # Response content type
  type: string # type of the transaction (default: unknown)
  value: int # value of the transaction
  wording: string # label of the transaction
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categorize"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: type, var: type}, {name: value, var: value}, {name: wording, var: wording}]}
    accept: ["application/json", failed, total, transactions]
    ok: [200]
    auth: bearer
  } {
    type: $type, value: $value, wording: $wording
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the latest certificate of a type
#
# GET /certificate/{type}
# Returns: record<created: string, id: int, id_private_key_file: int, id_public_key_file: int, type: string>
export def "get-certificate-type" [
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
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificate/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List clients
#
# GET /clients
# Returns: record<clients: table<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>, total: float>
export def "get-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/clients"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a client
#
# POST /clients
# Returns: record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>
export def "post-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # custom config about the client
  --generate-keys: oneof<nothing, bool> # if True, generate a rsa pair of keys so the client can be used to generate jwt user tokens (default: False)
  --name: string # name of client
  --redirect-uris: string # list of allowed redirect uris
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clients"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: config, var: config}, {name: generate_keys, var: generate_keys}, {name: name, var: name}, {name: redirect_uris, var: redirect_uris}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, config: $config, generate_keys: $generate_keys, name: $name, redirect_uris: $redirect_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a client
#
# DELETE /clients/{id_client}
# Returns: record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>
export def "delete-clients-id-client" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/clients/{id_client}"
    path_params: [{name: id_client, var: id_client}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_client: $id_client, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about a client
#
# GET /clients/{id_client}
# Returns: record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>
export def "get-clients-id-client" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/clients/{id_client}"
    path_params: [{name: id_client, var: id_client}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_client: $id_client, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a client
#
# PUT /clients/{id_client}
# Returns: record<config: string, id: int, id_logo: int, name: string, private_key: string, pro: bool, public_key: string, redirect_uris: string, secret: string>
export def "put-clients-id-client" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # custom config about the client
  --description: string # text to display as a default description
  --description-banks: string # text to display as a description for banks
  --description-providers: string # text to display as a description for providers
  --generate-keys: oneof<nothing, bool> # set a rsa key pair for the client, which make it possible to generate a jwt user token using this client. No effect if the client already has a set of keys(default: False)
  --name: string # name of client
  --primary-color: string # hexadecimal code of the client primary color (e.g F45B9A)
  --pro: oneof<nothing, bool> # Wether the client should display the company manager page
  --redirect-uris: string # list of allowed redirect uris
  --secondary-color: string # hexadecimal code of the client secondary color (e.g F45B9A)
  --secret: oneof<nothing, bool> # reset the secret
  --update-config: oneof<nothing, bool> # update the custom information about the client instead of replacing the existing one (default: True)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/clients/{id_client}"
    path_params: [{name: id_client, var: id_client}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: config, var: config}, {name: description, var: description}, {name: description_banks, var: description_banks}, {name: description_providers, var: description_providers}, {name: generate_keys, var: generate_keys}, {name: name, var: name}, {name: primary_color, var: primary_color}, {name: pro, var: pro}, {name: redirect_uris, var: redirect_uris}, {name: secondary_color, var: secondary_color}, {name: secret, var: secret}, {name: update_config, var: update_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_client: $id_client, expand: $expand, config: $config, description: $description, description_banks: $description_banks, description_providers: $description_providers, generate_keys: $generate_keys, name: $name, primary_color: $primary_color, pro: $pro, redirect_uris: $redirect_uris, secondary_color: $secondary_color, secret: $secret, update_config: $update_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the client logo
#
# DELETE /clients/{id_client}/logo
# Returns: record<content_type: string, file_size: int, filename: string, id: int>
export def "delete-clients-id-client-logo" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/clients/{id_client}/logo"
    path_params: [{name: id_client, var: id_client}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_client: $id_client, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the client logo
#
# POST /clients/{id_client}/logo
# Returns: record<content_type: string, file_size: int, filename: string, id: int>
export def "post-clients-id-client-logo" [
  id_client: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/clients/{id_client}/logo"
    path_params: [{name: id_client, var: id_client}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_client: $id_client, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration of the API.
#
# GET /config
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
  --search: string # limit the results to keys matching the given value
]: nothing -> any {
  http-request {
    method: get
    path: "/config"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert/update configuration key(s)/value(s) on the API.
#
# POST /config
export def "post-config" [
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
    path: "/config"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration change history of the API.
#
# GET /config/logs
# Returns: record<configlogs: table<id: int, key: string, new_value: string, origin: string, previous_value: string, timestamp: string, type: string>, total: float>
export def "get-config-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # limit the results to keys matching the given value
  --type: string # type of change done on the configuration
  --min-date: string # minimal date of the change (format: date)
  --max-date: string # maximum date of the change (format: date)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/config/logs"
    query: [{name: search, var: search}, {name: type, var: type}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, type: $type, min_date: $min_date, max_date: $max_date, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connections without a user
#
# GET /connections
# Returns: record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>
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
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection logs
#
# GET /connections/{id_connection}/logs
# Returns: record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>
export def "get-connections-id-connection-logs" [
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --qp-id-connection: int # ID of a connection (spec name: id_connection)
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections/{id_connection}/logs"
    path_params: [{name: id_connection, var: id_connection}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: period, var: period}, {name: id_user, var: id_user}, {name: id_connection, var: qp_id_connection}, {name: id_connector, var: id_connector}, {name: connector_uuid, var: connector_uuid}, {name: error, var: error}, {name: id_source, var: id_source}, {name: id_max, var: id_max}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connection: $id_connection, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, period: $period, id_user: $id_user, qp_id_connection: $qp_id_connection, id_connector: $id_connector, connector_uuid: $connector_uuid, error: $error, id_source: $id_source, id_max: $id_max, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection sources
#
# GET /connections/{id_connection}/sources
# Returns: record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>
export def "get-connections-id-connection-sources" [
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connections/{id_connection}/sources"
    path_params: [{name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a connection source
#
# DELETE /connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "delete-connections-id-connection-sources-id-source" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connection: $id_connection, id_source: $id_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# "
#
# POST /connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "post-connections-id-connection-sources-id-source" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the sysynchronizenc parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: background, var: background}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: disabled, var: disabled}, {name: synchronize, var: synchronize}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connection: $id_connection, id_source: $id_source, background: $background, expand: $expand, disabled: $disabled, synchronize: $synchronize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update connection source
#
# PUT /connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "put-connections-id-connection-sources-id-source" [
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the synchronize parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --force: oneof<nothing, bool> # whether to force the synchronization on the source if it's in error
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: background, var: background}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: disabled, var: disabled}, {name: force, var: force}, {name: synchronize, var: synchronize}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connection: $id_connection, id_source: $id_source, background: $background, expand: $expand, disabled: $disabled, force: $force, synchronize: $synchronize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of connectors
#
# GET /connectors
# Returns: record<connectors: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>
export def "get-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a new connector
#
# POST /connectors
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "post-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --comment: string # Optionnal comment
  --email: string # Email of the user
  login: string # Users login
  name: string # Name of the bank or provider
  password: string # Users password
  --sendmail: oneof<nothing, bool> # if set, send an email to user
  --types: string # Type of connector, eg. banks or providers
  --url: string # Url of the bank
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connectors"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: comment, var: comment}, {name: email, var: email}, {name: login, var: login}, {name: name, var: name}, {name: password, var: password}, {name: sendmail, var: sendmail}, {name: types, var: types}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, comment: $comment, email: $email, login: $login, name: $name, password: $password, sendmail: $sendmail, types: $types, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/disable several connectors
#
# PUT /connectors
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "put-connectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --hidden: oneof<nothing, bool> # to enable or disable connector (bank or provider)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/connectors"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: hidden, var: hidden}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, hidden: $hidden
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connector
#
# GET /connectors/{id_connector}
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "get-connectors-id-connector" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit the provided connector
#
# PUT /connectors/{id_connector}
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "put-connectors-id-connector" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-6 # Response content type
  --expand: string
  --auth-mechanism: string # the authentication mechanism to use for this connector
  --hidden: oneof<nothing, bool> # to enable or disable connector (bank or provider)
  --id-categories: string # one or several comma separated categories to map to the given connector (or null to map no category)
  --sync-frequency: int # Allows you to overload global sync_frequency param
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/connectors/{id_connector}"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: auth_mechanism, var: auth_mechanism}, {name: hidden, var: hidden}, {name: id_categories, var: id_categories}, {name: sync_frequency, var: sync_frequency}]}
    accept: ["application/json", auth_mechanism, beta, capabilities, categories, charged, code, color, hidden, id, name, slug, sync_frequency]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand, auth_mechanism: $auth_mechanism, hidden: $hidden, id_categories: $id_categories, sync_frequency: $sync_frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-connectors-id-connector-logos" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/logos"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a connector Logo
#
# POST /connectors/{id_connector}/logos
# Returns: record<id: int, id_connector: int, id_file: int, type: string>
export def "post-connectors-id-connector-logos" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/connectors/{id_connector}/logos"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Update a connector Logo
#
# PUT /connectors/{id_connector}/logos
# Returns: record<id: int, id_connector: int, id_file: int, type: string>
export def "put-connectors-id-connector-logos" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/connectors/{id_connector}/logos"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos/main
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-connectors-id-connector-logos-main" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/logos/main"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /connectors/{id_connector}/logos/thumbnail
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-connectors-id-connector-logos-thumbnail" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/logos/thumbnail"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single Logo object.
#
# DELETE /connectors/{id_connector}/logos/{id_logo}
# Returns: record<id: int, id_connector: int, id_file: int, type: string>
export def "delete-connectors-id-connector-logos-id-logo" [
  id_connector: int
  id_logo: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/connectors/{id_connector}/logos/{id_logo}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_logo, var: id_logo}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_logo: $id_logo, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Update a connector Logo.
#
# PUT /connectors/{id_connector}/logos/{id_logo}
# Returns: record<id: int, id_connector: int, id_file: int, type: string>
export def "put-connectors-id-connector-logos-id-logo" [
  id_connector: int
  id_logo: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/connectors/{id_connector}/logos/{id_logo}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_logo, var: id_logo}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_logo: $id_logo, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of connector sources
#
# GET /connectors/{id_connector}/sources
# Returns: record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>
export def "get-connectors-id-connector-sources" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/sources"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit several connector sources
#
# PUT /connectors/{id_connector}/sources
# Returns: record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>
export def "put-connectors-id-connector-sources" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --disabled-capabilities: string # list (json format) of capabilities the sources will be disabled for
  --unavailable-capabilities: string # list (json format) of capabilities the sources will be unavailable for
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/connectors/{id_connector}/sources"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: disabled_capabilities, var: disabled_capabilities}, {name: unavailable_capabilities, var: unavailable_capabilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand, disabled_capabilities: $disabled_capabilities, unavailable_capabilities: $unavailable_capabilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fields specific to a domain and a source
#
# GET /connectors/{id_connector}/sources/{id_connector_source}/fields
# Returns: record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>
export def "get-connectors-id-connector-sources-id-connector-source-fields" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/sources/{id_connector_source}/fields"
    path_params: [{name: id_connector, var: id_connector}, {name: id_connector_source, var: id_connector_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_connector_source: $id_connector_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the connector source
#
# GET /connectors/{id_connector}/sources/{id_source}
# Returns: record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>
export def "get-connectors-id-connector-sources-id-source" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/connectors/{id_connector}/sources/{id_source}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_source: $id_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit the provided connector source
#
# PUT /connectors/{id_connector}/sources/{id_source}
# Returns: record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>
export def "put-connectors-id-connector-sources-id-source" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --auth-mechanism: string # the authentication mechanism to use for this connector source
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --disabled-capabilities: string # list (json format) of capabilities this source will be disabled for
  --unavailable: oneof<nothing, bool> # to enable or disable the source (can only be edited by BI employees)
  --unavailable-capabilities: string # list (json format) of capabilities this source will be unavailable for
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/connectors/{id_connector}/sources/{id_source}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: auth_mechanism, var: auth_mechanism}, {name: disabled, var: disabled}, {name: disabled_capabilities, var: disabled_capabilities}, {name: unavailable, var: unavailable}, {name: unavailable_capabilities, var: unavailable_capabilities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_source: $id_source, expand: $expand, auth_mechanism: $auth_mechanism, disabled: $disabled, disabled_capabilities: $disabled_capabilities, unavailable: $unavailable, unavailable_capabilities: $unavailable_capabilities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get incidents logs.
#
# GET /incidents
export def "get-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # comma separated list, filter incidents in the given states.
  --id: int # give only the current state of the particular incidents.
  --weboob-id: string # comma_separated list, filter the incidents of the given weboob_id
  --start-date: string # filter last_update date >= start_date. YYYY-MM-DD format.
  --end-date: string # filter last_update date <= start_date. YYYY-MM-DD format.
  --page: int # pagination option. Default to 1.
  --size: int # pagination option. Default to 30.
]: nothing -> any {
  http-request {
    method: get
    path: "/incidents"
    query: [{name: state, var: state}, {name: id, var: id}, {name: weboob_id, var: weboob_id}, {name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state, id: $id, weboob_id: $weboob_id, start_date: $start_date, end_date: $end_date, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoicing data for a given period (default is the current month).
#
# GET /invoicing
export def "get-invoicing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --users-synced: string # the number of user synchronized during the period
  --users-bank: string # the number of user of the Bank API synchronized during the period
  --users-bill: string # the number of user of the Bill API synchronized during the period
  --accounts-synced: string # the number of accounts synchronized during the period
  --subscriptions-synced: string # the number of subscriptions synchronized during the period
  --connections-synced: string # the number of connections synchronized during the period
  --connections-account: string # the number of Bank API connections synchronized during the period
  --transfers-synced: string # the number of transfers done during the period
  --payments-synced: string # the number of payments done during the period
  --all: string # get all the invoicing data at once
  --detail: string # get full ids list instead of numbers
]: nothing -> any {
  http-request {
    method: get
    path: "/invoicing"
    query: [{name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: users_synced, var: users_synced}, {name: users_bank, var: users_bank}, {name: users_bill, var: users_bill}, {name: accounts_synced, var: accounts_synced}, {name: subscriptions_synced, var: subscriptions_synced}, {name: connections_synced, var: connections_synced}, {name: connections_account, var: connections_account}, {name: transfers_synced, var: transfers_synced}, {name: payments_synced, var: payments_synced}, {name: all, var: all}, {name: detail, var: detail}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    min_date: $min_date, max_date: $max_date, users_synced: $users_synced, users_bank: $users_bank, users_bill: $users_bill, accounts_synced: $accounts_synced, subscriptions_synced: $subscriptions_synced, connections_synced: $connections_synced, connections_account: $connections_account, transfers_synced: $transfers_synced, payments_synced: $payments_synced, all: $all, detail: $detail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection logs
#
# GET /logs
# Returns: record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>
export def "get-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --id-user: int # ID of a user
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/logs"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: period, var: period}, {name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_connector, var: id_connector}, {name: connector_uuid, var: connector_uuid}, {name: error, var: error}, {name: id_source, var: id_source}, {name: id_max, var: id_max}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, period: $period, id_user: $id_user, id_connection: $id_connection, id_connector: $id_connector, connector_uuid: $connector_uuid, error: $error, id_source: $id_source, id_max: $id_max, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get performances stats on this instance
#
# GET /monitoring
export def "get-monitoring" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: int # number on days on which stats on synchronization have to be done per worker (Default: 1)
]: nothing -> any {
  http-request {
    method: get
    path: "/monitoring"
    query: [{name: period, var: period}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of connectors
#
# GET /providers
# Returns: record<providers: table<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>, total: float>
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
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a random subset of provider's id_connection
#
# GET /providers/{id_connector}/connections
# Returns: record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>
export def "get-providers-id-connector-connections" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range: int # the length of the connection subset
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/connections"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: range, var: range}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, range: $range, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-providers-id-connector-logos" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/logos"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos/main
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-providers-id-connector-logos-main" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/logos/main"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all links to the files associated with this connector.
#
# GET /providers/{id_connector}/logos/thumbnail
# Returns: record<connectorlogos: table<id: int, id_connector: int, id_file: int, type: string>, total: float>
export def "get-providers-id-connector-logos-thumbnail" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/logos/thumbnail"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of connector sources
#
# GET /providers/{id_connector}/sources
# Returns: record<sources: table<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>, total: float>
export def "get-providers-id-connector-sources" [
  id_connector: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/sources"
    path_params: [{name: id_connector, var: id_connector}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get fields specific to a domain and a source
#
# GET /providers/{id_connector}/sources/{id_connector_source}/fields
# Returns: record<source_fields: table<id_connector_source: int, label: string, name: string, regex: string, required: bool, secret: bool, type: string>, total: float>
export def "get-providers-id-connector-sources-id-connector-source-fields" [
  id_connector: int
  id_connector_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/sources/{id_connector_source}/fields"
    path_params: [{name: id_connector, var: id_connector}, {name: id_connector_source, var: id_connector_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_connector_source: $id_connector_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the connector source
#
# GET /providers/{id_connector}/sources/{id_source}
# Returns: record<auth_mechanism: string, disabled: string, disabled_capabilities: string, fallback: string, id: int, id_connector: int, id_weboob: string, name: string, priority: int, stability: string>
export def "get-providers-id-connector-sources-id-source" [
  id_connector: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_connector}/sources/{id_source}"
    path_params: [{name: id_connector, var: id_connector}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_connector: $id_connector, id_source: $id_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a connector
#
# GET /providers/{id_provider}
# Returns: record<auth_mechanism: string, beta: bool, charged: bool, code: string, color: string, hidden: bool, id: int, months_to_fetch: int, name: string, restricted: bool, siret: string, slug: string, sync_frequency: float, uuid: string>
export def "get-providers-id-provider" [
  id_provider: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/{id_provider}"
    path_params: [{name: id_provider, var: id_provider}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_provider: $id_provider, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details on all psd2 registrations
#
# GET /psd2-registrations
# Returns: record<psd2registrations: table<id: int, id_connector_source: int, status: string>, total: float>
export def "get-psd2-registrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/psd2-registrations"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details for a given psd2 registration
#
# GET /psd2-registrations/{id_psd2-registration}
# Returns: record<id: int, id_connector_source: int, status: string>
export def "get-psd2-registrations-id-psd2-registration" [
  id_psd2_registration: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/psd2-registrations/{id_psd2-registration}"
    path_params: [{name: id_psd2-registration, var: id_psd2_registration}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_psd2_registration: $id_psd2_registration, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get psd2 registration logs.
#
# GET /psd2-registrations/{id_psd2registration}/logs
# Returns: record<psd2registrationlogs: table<created_at: string, error_message: string, id: int, id_psd2registration: int, type: string>, total: float>
export def "get-psd2-registrations-id-psd2registration-logs" [
  id_psd2registration: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/psd2-registrations/{id_psd2registration}/logs"
    path_params: [{name: id_psd2registration, var: id_psd2registration}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_psd2registration: $id_psd2registration, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get public encryption key of the API.
#
# GET /publickey
export def "get-publickey" [
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
    path: "/publickey"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test synchronization on a random connection.
#
# POST /test/sync
export def "post-test-sync" [
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
    path: "/test/sync"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test synchronization on a random connection.
#
# POST /test/webhooks
export def "post-test-webhooks" [
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
    path: "/test/webhooks"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users
#
# GET /users
# Returns: record<total: float, users: table<id: int, platform: string, signin: string>>
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
  --search: string # searches a user by mail (if it contains no '@', '@biapi.pro' will be added at the end)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: search, var: search}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the user
#
# DELETE /users/{id_user}
# Returns: record<id: int, platform: string, signin: string>
export def "delete-users-id-user" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{id_user}
# Returns: record<id: int, platform: string, signin: string>
export def "get-users-id-user" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account types
#
# GET /users/{id_user}/account_types
# Returns: record<accounttypes: table<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>, total: float>
export def "get-users-id-user-account-types" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/account_types"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an account type
#
# GET /users/{id_user}/account_types/{id_account_type}
# Returns: record<color: string, display_name: string, display_name_p: string, id: int, id_parent: int, is_invest: bool, name: string, product: string, weboob_type_id: int>
export def "get-users-id-user-account-types-id-account-type" [
  id_user: string
  id_account_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/account_types/{id_account_type}"
    path_params: [{name: id_user, var: id_user}, {name: id_account_type, var: id_account_type}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account_type: $id_account_type, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the category
#
# GET /users/{id_user}/accounts/{id_account}/categories
export def "get-users-id-user-accounts-id-account-categories" [
  id_user: string
  id_account: int
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
    path: "/users/{id_user}/accounts/{id_account}/categories"
    path_params: [{name: id_user, var: id_user}, {name: id_account, var: id_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account: $id_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clustered transactions
#
# GET /users/{id_user}/accounts/{id_account}/transactionsclusters
# Returns: record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>
export def "get-users-id-user-accounts-id-account-transactionsclusters" [
  id_user: string
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/accounts/{id_account}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clustered transaction
#
# POST /users/{id_user}/accounts/{id_account}/transactionsclusters
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "post-users-id-user-accounts-id-account-transactionsclusters" [
  id_user: string
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{id_user}/accounts/{id_account}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "delete-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_account, var: id_account}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account: $id_account, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "put-users-id-user-accounts-id-account-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_account, var: id_account}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_account: $id_account, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get alerts
#
# GET /users/{id_user}/alerts
# Returns: record<alerts: table<id: int, id_account: int, id_investment: int, id_transaction: int, id_user: int, timestamp: string, type: string, value: float>, total: float>
export def "get-users-id-user-alerts" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/alerts"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the category
#
# GET /users/{id_user}/categories
export def "get-users-id-user-categories" [
  id_user: string
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
    path: "/users/{id_user}/categories"
    path_params: [{name: id_user, var: id_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the category
#
# GET /users/{id_user}/categories/full
# Returns: record<categorys: table<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>, total: float>
export def "get-users-id-user-categories-full" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/categories/full"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new transaction category
#
# POST /users/{id_user}/categories/full
# Returns: record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>
export def "post-users-id-user-categories-full" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --accountant-account: string # Accountant account number.
  --color: string # Color of the category.
  --id-parent-category: int # ID of the parent category.
  --id-parent-category-in-menu: int # ID of the parent category to be displayed.
  --income: oneof<nothing, bool> # Is an income category. If null, this is both an income and an expense category.
  --name: string # Name of the category.
  --refundable: oneof<nothing, bool> # This category accepts opposite sign of transactions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/categories/full"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: accountant_account, var: accountant_account}, {name: color, var: color}, {name: id_parent_category, var: id_parent_category}, {name: id_parent_category_in_menu, var: id_parent_category_in_menu}, {name: income, var: income}, {name: name, var: name}, {name: refundable, var: refundable}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand, accountant_account: $accountant_account, color: $color, id_parent_category: $id_parent_category, id_parent_category_in_menu: $id_parent_category_in_menu, income: $income, name: $name, refundable: $refundable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user-created transaction category
#
# DELETE /users/{id_user}/categories/full/{id_full}
# Returns: record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>
export def "delete-users-id-user-categories-full-id-full" [
  id_user: string
  id_full: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/categories/full/{id_full}"
    path_params: [{name: id_user, var: id_user}, {name: id_full, var: id_full}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_full: $id_full, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a user-created category
#
# PUT /users/{id_user}/categories/full/{id_full}
# Returns: record<color: string, id: int, id_logo: int, id_parent_category: int, id_parent_category_in_menu: int, id_user: int, income: bool, name: string, name_displayed: string, refundable: bool>
export def "put-users-id-user-categories-full-id-full" [
  id_user: string
  id_full: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --accountant-account: string # Accountant account number.
  --hide: string # Hide (but not delete) a category. Must be 0, 1 or toggle.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id_user}/categories/full/{id_full}"
    path_params: [{name: id_user, var: id_user}, {name: id_full, var: id_full}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: accountant_account, var: accountant_account}, {name: hide, var: hide}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_full: $id_full, expand: $expand, accountant_account: $accountant_account, hide: $hide
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the given user configurations. deletions on keys prefixed by 'biapi.' (except callback_url) are ignored
#
# DELETE /users/{id_user}/config
export def "delete-users-id-user-config" [
  id_user: string
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
    path: "/users/{id_user}/config"
    path_params: [{name: id_user, var: id_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration of a user.
#
# GET /users/{id_user}/config
# Returns: record
export def "get-users-id-user-config" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-7 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/config"
    path_params: [{name: id_user, var: id_user}]
    accept: ["application/json", "biapi.last_push"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change configuration of a user. modifications on keys prefixed by 'biapi.' (except callback_url) are ignored
#
# POST /users/{id_user}/config
export def "post-users-id-user-config" [
  id_user: string
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
    path: "/users/{id_user}/config"
    path_params: [{name: id_user, var: id_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all connections
#
# DELETE /users/{id_user}/connections
# Returns: record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>
export def "delete-users-id-user-connections" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connections
#
# GET /users/{id_user}/connections
# Returns: record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>
export def "get-users-id-user-connections" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new connection.
#
# POST /users/{id_user}/connections
# Returns: record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>
export def "post-users-id-user-connections" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # optional comma-separated list of sources to use for the connection synchronization
  --expand: string
  --connector-uuid: string # optional uuid of the connector (replaces id_connector)
  --id-connector: int # ID of the connector
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/connections"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: source, var: source}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: connector_uuid, var: connector_uuid}, {name: id_connector, var: id_connector}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, source: $source, expand: $expand, connector_uuid: $connector_uuid, id_connector: $id_connector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a connection.
#
# DELETE /users/{id_user}/connections/{id_connection}
# Returns: record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>
export def "delete-users-id-user-connections-id-connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a connection.
#
# POST /users/{id_user}/connections/{id_connection}
# Returns: record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>
export def "post-users-id-user-connections-id-connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # Do the connection update/synchronization in background
  --psu-requested: oneof<nothing, bool> # Whether the connection synchronization is asked by the PSU or not (default is true)
  --refresh-psd2-auth: oneof<nothing, bool> # Refresh the PSU's SCA for openapi source
  --expand: string
  --active: oneof<nothing, bool> # Set if the connection synchronization is active
  --decoupled: oneof<nothing, bool> # Try to update a connection with the decoupled error
  --expire: string # Set expiration of the connection to this date (format: date-time)
  --login: string # Set login to this new login
  --password: string # Set password to this new password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: background, var: background}, {name: psu_requested, var: psu_requested}, {name: refresh_psd2_auth, var: refresh_psd2_auth}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: active, var: active}, {name: decoupled, var: decoupled}, {name: expire, var: expire}, {name: login, var: login}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, background: $background, psu_requested: $psu_requested, refresh_psd2_auth: $refresh_psd2_auth, expand: $expand, active: $active, decoupled: $decoupled, expire: $expire, login: $login, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force synchronisation of a connection.
#
# PUT /users/{id_user}/connections/{id_connection}
# Returns: record<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>
export def "put-users-id-user-connections-id-connection" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-update: string # if supplied, get transactions inserted since this date (format: date-time)
  --background: oneof<nothing, bool> # do the connection synchronization in background
  --psu-requested: oneof<nothing, bool> # Whether the connection synchronization is asked by the PSU or not (default is true)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: last_update, var: last_update}, {name: background, var: background}, {name: psu_requested, var: psu_requested}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, last_update: $last_update, background: $background, psu_requested: $psu_requested, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all accounts
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts
# Returns: record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>
export def "delete-users-id-user-connections-id-connection-accounts" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get accounts list.
#
# GET /users/{id_user}/connections/{id_connection}/accounts
# Returns: record<accounts: table<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>, total: float>
export def "get-users-id-user-connections-id-connection-accounts" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an account
#
# POST /users/{id_user}/connections/{id_connection}/accounts
# Returns: record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>
export def "post-users-id-user-connections-id-connection-accounts" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --balance: float # balance of account (format: float)
  --iban: string # IBAN of account
  --body-id-connection: int # the connection to attach to the account (spec name: id_connection)
  --id-currency: string # the currency of the account (default: 'EUR')
  name: string # name of account
  --number: string # number of account
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}/accounts"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: balance, var: balance}, {name: iban, var: iban}, {name: id_connection, var: body_id_connection}, {name: id_currency, var: id_currency}, {name: name, var: name}, {name: number, var: number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand, balance: $balance, iban: $iban, body_id_connection: $body_id_connection, id_currency: $id_currency, name: $name, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update many accounts at once
#
# PUT /users/{id_user}/connections/{id_connection}/accounts
# Returns: record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>
export def "put-users-id-user-connections-id-connection-accounts" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/accounts"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an account.
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}
# Returns: record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>
export def "delete-users-id-user-connections-id-connection-accounts-id-account" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an account
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}
# Returns: record<balance: float, bookmarked: int, coming: float, company_name: string, currency: record, deleted: string, disabled: string, display: bool, error: string, iban: string, id: int, id_connection: int, id_parent: int, id_source: int, id_type: int, id_user: int, last_update: string, name: string, number: string, opening_date: string, original_name: string, ownership: string, usage: string, webid: string>
export def "put-users-id-user-connections-id-connection-accounts-id-account" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --balance: float # Balance of the account (format: float)
  --bookmarked: oneof<nothing, bool> # If the account is bookmarked
  --disabled: oneof<nothing, bool> # If the account is disabled (not synchronized)
  --display: oneof<nothing, bool> # If the account is displayed
  --iban: string # IBAN of the account
  --name: string # Label of the account
  --usage: string # Usage of the account : PRIV, ORGA or ASSO
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: balance, var: balance}, {name: bookmarked, var: bookmarked}, {name: disabled, var: disabled}, {name: display, var: display}, {name: iban, var: iban}, {name: name, var: name}, {name: usage, var: usage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand, balance: $balance, bookmarked: $bookmarked, disabled: $disabled, display: $display, iban: $iban, name: $name, usage: $usage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the category
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/categories
export def "get-users-id-user-connections-id-connection-accounts-id-account-categories" [
  id_user: string
  id_connection: int
  id_account: int
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
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/categories"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get deltas of accounts
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/delta
export def "get-users-id-user-connections-id-connection-accounts-id-account-delta" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/delta"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: period, var: period}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, min_date: $min_date, max_date: $max_date, period: $period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get accounts logs.
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/logs
# Returns: record<accountlogs: table<balance: float, coming: float, error: string, error_message: string, id: int, id_account: int, id_connection_log: int, id_connector: int, timestamp: string>, total: float>
export def "get-users-id-user-connections-id-connection-accounts-id-account-logs" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/logs"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account sources
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/sources
# Returns: record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>
export def "get-users-id-user-connections-id-connection-accounts-id-account-sources" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/sources"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete transactions
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
# Returns: record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>
export def "delete-users-id-user-connections-id-connection-accounts-id-account-transactions" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get transactions
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
# Returns: record<total: float, transactions: table<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>>
export def "get-users-id-user-connections-id-connection-accounts-id-account-transactions" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --income: oneof<nothing, bool> # filter on income or expenditures
  --deleted: oneof<nothing, bool> # display only deleted transactions
  --all: oneof<nothing, bool> # display all transactions, including deleted ones
  --last-update: string # get only transactions updated after the specified datetime (format: date-time)
  --wording: string # filter transactions containing the given string
  --min-value: float # minimal (inclusive) value (format: float)
  --max-value: float # maximum (inclusive) value (format: float)
  --search: string # search in labels, dates, values and categories
  --value: string # "XX|-XX" or "±XX"
  --id-category: int # filter on given category id(s) (comma separated) or "null"
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: income, var: income}, {name: deleted, var: deleted}, {name: all, var: all}, {name: last_update, var: last_update}, {name: wording, var: wording}, {name: min_value, var: min_value}, {name: max_value, var: max_value}, {name: search, var: search}, {name: value, var: value}, {name: id_category, var: id_category}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, income: $income, deleted: $deleted, all: $all, last_update: $last_update, wording: $wording, min_value: $min_value, max_value: $max_value, search: $search, value: $value, id_category: $id_category, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create transactions
#
# POST /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions
# Returns: record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>
export def "post-users-id-user-connections-id-connection-accounts-id-account-transactions" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --active: oneof<nothing, bool> # 1 if the transaction should be taken into account by pfm services (default: 1)
  --coming: oneof<nothing, bool> # 1 if the transaction has already been debited (default: 0)
  date: string # date of the transaction (format: date)
  --date-scraped: string # date on which the transaction has been found for the first time. YYYY-MM-DD HH:MM:SS(default: now) (format: date-time)
  --body-id-account: int # account of the transaction. If not supplied, it has to be given in the route (spec name: id_account)
  original_wording: string # label of the transaction
  --rdate: string # realisation date of the transaction (default: value of date) (format: date)
  --state: string # nature of the transaction (default: new)
  --type: string # type of the transaction (default: unknown)
  value: int # vallue of the transaction
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: active, var: active}, {name: coming, var: coming}, {name: date, var: date}, {name: date_scraped, var: date_scraped}, {name: id_account, var: body_id_account}, {name: original_wording, var: original_wording}, {name: rdate, var: rdate}, {name: state, var: state}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand, active: $active, coming: $coming, date: $date, date_scraped: $date_scraped, body_id_account: $body_id_account, original_wording: $original_wording, rdate: $rdate, state: $state, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a transaction meta-data
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}
# Returns: record<active: bool, application_date: string, bdate: string, bdatetime: string, card: string, coming: bool, comment: string, commission: float, commission_currency: record, counterparty: string, country: string, date: string, date_scraped: string, datetime: string, deleted: string, gross_value: float, id: int, id_account: int, id_category: int, id_cluster: int, last_update: string, nature: string, original_currency: record, original_gross_value: float, original_value: float, original_wording: string, rdate: string, rdatetime: string, simplified_wording: string, state: string, stemmed_wording: string, value: float, vdate: string, vdatetime: string, webid: string, wording: string>
export def "put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --active: oneof<nothing, bool> # if false, transaction isn't considered in analyzisis endpoints (like /balances)
  --application-date: string # change application date of the transaction (format: date)
  --comment: string # change comment
  --id-category: int # ID of the associated category
  --wording: string # user rewording of the transaction
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: active, var: active}, {name: application_date, var: application_date}, {name: comment, var: comment}, {name: id_category, var: id_category}, {name: wording, var: wording}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, expand: $expand, active: $active, application_date: $application_date, comment: $comment, id_category: $id_category, wording: $wording
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all arbitrary key-value pairs of a transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
# Returns: record<id: int, id_transaction: int, key: string, value: string>
export def "delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all arbitrary key-value pairs on a transaction
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
# Returns: record<total: float, transactioninformations: table<id: int, id_transaction: int, key: string, value: string>>
export def "get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or edit transaction arbitrary key-value pairs
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations
# Returns: record<id: int, id_transaction: int, key: string, value: string>
export def "put-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a particular key-value pair on a transaction.
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}
# Returns: record<id: int, id_transaction: int, key: string, value: string>
export def "delete-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  id_information: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}, {name: id_information, var: id_information}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, id_information: $id_information, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a particular arbitrary key-value pair on a transaction
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}
# Returns: record<id: int, id_transaction: int, key: string, value: string>
export def "get-users-id-user-connections-id-connection-accounts-id-account-transactions-id-transaction-informations-id-information" [
  id_user: string
  id_connection: int
  id_account: int
  id_transaction: int
  id_information: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactions/{id_transaction}/informations/{id_information}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transaction, var: id_transaction}, {name: id_information, var: id_information}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transaction: $id_transaction, id_information: $id_information, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clustered transactions
#
# GET /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters
# Returns: record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>
export def "get-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clustered transaction
#
# POST /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "post-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters" [
  id_user: string
  id_connection: int
  id_account: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "delete-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_connection: int
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "put-users-id-user-connections-id-connection-accounts-id-account-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_connection: int
  id_account: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/accounts/{id_account}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_account, var: id_account}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_account: $id_account, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection additionnal informations
#
# GET /users/{id_user}/connections/{id_connection}/informations
# Returns: record<connections: table<active: bool, created: string, id: int, id_connector: int, id_user: int, last_push: string, last_update: string, next_try: string>, total: float>
export def "get-users-id-user-connections-id-connection-informations" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-8 # Response content type
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/informations"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json", compagny, owner]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get connection logs
#
# GET /users/{id_user}/connections/{id_connection}/logs
# Returns: record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>
export def "get-users-id-user-connections-id-connection-logs" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --qp-id-user: int # ID of a user (spec name: id_user)
  --qp-id-connection: int # ID of a connection (spec name: id_connection)
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/logs"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: period, var: period}, {name: id_user, var: qp_id_user}, {name: id_connection, var: qp_id_connection}, {name: id_connector, var: id_connector}, {name: connector_uuid, var: connector_uuid}, {name: error, var: error}, {name: id_source, var: id_source}, {name: id_max, var: id_max}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, period: $period, qp_id_user: $qp_id_user, qp_id_connection: $qp_id_connection, id_connector: $id_connector, connector_uuid: $connector_uuid, error: $error, id_source: $id_source, id_max: $id_max, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection sources
#
# GET /users/{id_user}/connections/{id_connection}/sources
# Returns: record<sources: table<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>, total: float>
export def "get-users-id-user-connections-id-connection-sources" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/sources"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a connection source
#
# DELETE /users/{id_user}/connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "delete-users-id-user-connections-id-connection-sources-id-source" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_source: $id_source, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# "
#
# POST /users/{id_user}/connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "post-users-id-user-connections-id-connection-sources-id-source" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the sysynchronizenc parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: background, var: background}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: disabled, var: disabled}, {name: synchronize, var: synchronize}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_source: $id_source, background: $background, expand: $expand, disabled: $disabled, synchronize: $synchronize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update connection source
#
# PUT /users/{id_user}/connections/{id_connection}/sources/{id_source}
# Returns: record<access_expire: string, created: string, disabled: string, expire: string, id: int, id_connection: int, id_connector_source: int, last_update: string, name: string, next_try: string, state: string>
export def "put-users-id-user-connections-id-connection-sources-id-source" [
  id_user: string
  id_connection: int
  id_source: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background: oneof<nothing, bool> # do the synchronization in background (to use with the synchronize parameter)
  --expand: string
  --disabled: oneof<nothing, bool> # to enable or disable connector source
  --force: oneof<nothing, bool> # whether to force the synchronization on the source if it's in error
  --synchronize: oneof<nothing, bool> # whether to force a synchronization on the source if it's not disabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/sources/{id_source}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_source, var: id_source}]
    query: [{name: background, var: background}, {name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: disabled, var: disabled}, {name: force, var: force}, {name: synchronize, var: synchronize}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_source: $id_source, background: $background, expand: $expand, disabled: $disabled, force: $force, synchronize: $synchronize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get clustered transactions
#
# GET /users/{id_user}/connections/{id_connection}/transactionsclusters
# Returns: record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>
export def "get-users-id-user-connections-id-connection-transactionsclusters" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/connections/{id_connection}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clustered transaction
#
# POST /users/{id_user}/connections/{id_connection}/transactionsclusters
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "post-users-id-user-connections-id-connection-transactionsclusters" [
  id_user: string
  id_connection: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{id_user}/connections/{id_connection}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "delete-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_connection: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "put-users-id-user-connections-id-connection-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_connection: int
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/connections/{id_connection}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_connection, var: id_connection}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_connection: $id_connection, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get forecast
#
# GET /users/{id_user}/forecast
export def "get-users-id-user-forecast" [
  id_user: string
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
    path: "/users/{id_user}/forecast"
    path_params: [{name: id_user, var: id_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection logs
#
# GET /users/{id_user}/logs
# Returns: record<connectionlogs: table<error: string, error_message: string, error_uid: string, fields: string, id: int, id_connection: int, id_connector: int, id_source: int, id_user: int, login: string, nb_accounts: int, next_try: string, session_folder_id: string, start: string, statut: int, timestamp: string, worker: string>, total: float>
export def "get-users-id-user-logs" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal date (format: date)
  --max-date: string # maximum date (format: date)
  --period: string # period to group logs
  --qp-id-user: int # ID of a user (spec name: id_user)
  --id-connection: int # ID of a connection
  --id-connector: int # ID of a connector
  --connector-uuid: string # UUID of a connector
  --error: string # connections log error filter
  --id-source: int # ID of a source
  --id-max: int # filter "id" of logs, maximum id to return
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/logs"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: period, var: period}, {name: id_user, var: qp_id_user}, {name: id_connection, var: id_connection}, {name: id_connector, var: id_connector}, {name: connector_uuid, var: connector_uuid}, {name: error, var: error}, {name: id_source, var: id_source}, {name: id_max, var: id_max}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, period: $period, qp_id_user: $qp_id_user, id_connection: $id_connection, id_connector: $id_connector, connector_uuid: $connector_uuid, error: $error, id_source: $id_source, id_max: $id_max, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get profiles
#
# GET /users/{id_user}/profiles
# Returns: record<profiles: table<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>, total: float>
export def "get-users-id-user-profiles" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/profiles"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the main profile
#
# GET /users/{id_user}/profiles/main
# Returns: record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>
export def "get-users-id-user-profiles-main" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/profiles/main"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a profile
#
# GET /users/{id_user}/profiles/{id_profile}
# Returns: record<admin: bool, conf: string, email: string, id: int, id_user: int, lang: string, role: string, statut: int>
export def "get-users-id-user-profiles-id-profile" [
  id_user: string
  id_profile: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/profiles/{id_profile}"
    path_params: [{name: id_user, var: id_user}, {name: id_profile, var: id_profile}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_profile: $id_profile, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a token
#
# POST /users/{id_user}/token
# Returns: record
export def "post-users-id-user-token" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-9 # Response content type
  application: string # application name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{id_user}/token"
    path_params: [{name: id_user, var: id_user}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: application, var: application}]}
    accept: ["application/json", token]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, application: $application
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get clustered transactions
#
# GET /users/{id_user}/transactionsclusters
# Returns: record<total: float, transactionsclusters: table<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>>
export def "get-users-id-user-transactionsclusters" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{id_user}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clustered transaction
#
# POST /users/{id_user}/transactionsclusters
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "post-users-id-user-transactionsclusters" [
  id_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{id_user}/transactionsclusters"
    path_params: [{name: id_user, var: id_user}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a clustered transaction
#
# DELETE /users/{id_user}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "delete-users-id-user-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{id_user}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a clustered transaction
#
# PUT /users/{id_user}/transactionsclusters/{id_transactionscluster}
# Returns: record<created_by: string, enabled: bool, id: int, id_account: int, id_category: int, mean_amount: float, median_increment: int, next_date: string, wording: string>
export def "put-users-id-user-transactionsclusters-id-transactionscluster" [
  id_user: string
  id_transactionscluster: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/users/{id_user}/transactionsclusters/{id_transactionscluster}"
    path_params: [{name: id_user, var: id_user}, {name: id_transactionscluster, var: id_transactionscluster}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_user: $id_user, id_transactionscluster: $id_transactionscluster, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# First step to establish an oAuth2 connection.
#
# GET /webauth
export def "get-webauth" [
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
    path: "/webauth"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all webhooks
#
# DELETE /webhooks
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "delete-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhooks
#
# GET /webhooks
# Returns: record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>>
export def "get-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new webhook
#
# POST /webhooks
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --event: string # The webhook event
  --id-auth: string # The webhook authentication process to use (its ID or its name)
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --params: string # The webhook parameters as an object with three keys: type, key and value
  --url: string # The webhook callback url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: event, var: event}, {name: id_auth, var: id_auth}, {name: id_service, var: id_service}, {name: id_user, var: id_user}, {name: params, var: params}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, event: $event, id_auth: $id_auth, id_service: $id_service, id_user: $id_user, params: $params, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all webhook authentication types
#
# DELETE /webhooks/auth
# Returns: record<id: int, name: string, type: string>
export def "delete-webhooks-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/auth"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhooks authentication types
#
# GET /webhooks/auth
# Returns: record<authproviders: table<id: int, name: string, type: string>, total: float>
export def "get-webhooks-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/auth"
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a new webhook authentication type
#
# POST /webhooks/auth
# Returns: record<id: int, name: string, type: string>
export def "post-webhooks-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict contains either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/auth"
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: config, var: config}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    expand: $expand, config: $config, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the webhook authentication type
#
# DELETE /webhooks/auth/{id_auth}
# Returns: record<id: int, name: string, type: string>
export def "delete-webhooks-auth-id-auth" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/auth/{id_auth}"
    path_params: [{name: id_auth, var: id_auth}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_auth: $id_auth, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the webhook authentication type
#
# POST /webhooks/auth/{id_auth}
# Returns: record<id: int, name: string, type: string>
export def "post-webhooks-auth-id-auth" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict containing either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/auth/{id_auth}"
    path_params: [{name: id_auth, var: id_auth}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: config, var: config}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_auth: $id_auth, expand: $expand, config: $config, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the webhook authentication type
#
# PUT /webhooks/auth/{id_auth}
# Returns: record<id: int, name: string, type: string>
export def "put-webhooks-auth-id-auth" [
  id_auth: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --config: string # The authentication process configuration. A dict containt either the certificate
  name: string # The name of the authentication process to differentiate
  type: int # The type of the authentication process (oauth, certificate, token, etc...)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/auth/{id_auth}"
    path_params: [{name: id_auth, var: id_auth}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: config, var: config}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_auth: $id_auth, expand: $expand, config: $config, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a webhook
#
# DELETE /webhooks/{id_webhook}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "delete-webhooks-id-webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/{id_webhook}"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a webhook
#
# POST /webhooks/{id_webhook}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "post-webhooks-id-webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --deleted: string # a date to delete the webhook or 'null' to enable it
  --event: string # The webhook event
  --id-auth: int # The webhook authentication process to use
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --url: string # The webhook callback url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks/{id_webhook}"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: deleted, var: deleted}, {name: event, var: event}, {name: id_auth, var: id_auth}, {name: id_service, var: id_service}, {name: id_user, var: id_user}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand, deleted: $deleted, event: $event, id_auth: $id_auth, id_service: $id_service, id_user: $id_user, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a webhook
#
# PUT /webhooks/{id_webhook}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "put-webhooks-id-webhook" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
  --deleted: string # a date to delete the webhook or 'null' to enable it
  --event: string # The webhook event
  --id-auth: int # The webhook authentication process to use
  --id-service: int # The service ID to associate with the webhook
  --id-user: int # The user ID to associate with the webhook
  --url: string # The webhook callback url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{id_webhook}"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: deleted, var: deleted}, {name: event, var: event}, {name: id_auth, var: id_auth}, {name: id_service, var: id_service}, {name: id_user, var: id_user}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand, deleted: $deleted, event: $event, id_auth: $id_auth, id_service: $id_service, id_user: $id_user, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete all entries
#
# DELETE /webhooks/{id_webhook}/add_to_data
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "delete-webhooks-id-webhook-add-to-data" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/{id_webhook}/add_to_data"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# retrieve the list of the value to add in webhooks when sending the requested webhook
#
# GET /webhooks/{id_webhook}/add_to_data
# Returns: record<total: float, webhooks: table<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>>
export def "get-webhooks-id-webhook-add-to-data" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id_webhook}/add_to_data"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Setup a field to store in user config when calling the endpoint
#
# POST /webhooks/{id_webhook}/add_to_data
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "post-webhooks-id-webhook-add-to-data" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/{id_webhook}/add_to_data"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete the requested entry
#
# DELETE /webhooks/{id_webhook}/add_to_data/{key}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "delete-webhooks-id-webhook-add-to-data-key" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/{id_webhook}/add_to_data/{key}"
    path_params: [{name: id_webhook, var: id_webhook}, {name: key, var: key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, key: $key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# retrieve the value to add in the requested webhook for the requested name
#
# GET /webhooks/{id_webhook}/add_to_data/{key}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "get-webhooks-id-webhook-add-to-data-key" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id_webhook}/add_to_data/{key}"
    path_params: [{name: id_webhook, var: id_webhook}, {name: key, var: key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, key: $key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# upate the requested field to store in user config when calling the endpoint
#
# POST /webhooks/{id_webhook}/add_to_data/{key}
# Returns: record<add_to_data: string, created: string, deleted: string, flush_fail: string, id: int, id_auth: int, id_event: int, id_service: int, id_user: int, updated: string, url: string>
export def "post-webhooks-id-webhook-add-to-data-key" [
  id_webhook: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/webhooks/{id_webhook}/add_to_data/{key}"
    path_params: [{name: id_webhook, var: id_webhook}, {name: key, var: key}]
    query: [{name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, key: $key, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webhooks logs.
#
# GET /webhooks/{id_webhook}/logs
# Returns: record<total: float, webhooklogs: table<id: int, id_service: int, id_user: int, id_webhook_data: int, next_try: string, response_code: int, response_date: string, timestamp: string>>
export def "get-webhooks-id-webhook-logs" [
  id_webhook: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-user: int # limit number of results to this user
  --limit: int # limit number of results
  --offset: int # offset of first result
  --min-date: string # minimal (inclusive) date (format: date)
  --max-date: string # maximum (inclusive) date (format: date)
  --expand: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{id_webhook}/logs"
    path_params: [{name: id_webhook, var: id_webhook}]
    query: [{name: id_user, var: id_user}, {name: limit, var: limit}, {name: offset, var: offset}, {name: min_date, var: min_date}, {name: max_date, var: max_date}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_webhook: $id_webhook, id_user: $id_user, limit: $limit, offset: $offset, min_date: $min_date, max_date: $max_date, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
