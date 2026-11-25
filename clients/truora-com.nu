# Auto-generated client for Checks API v1.0.0
# Source: https://api.apis.guru/v2/specs/truora.com/1.0.0/openapi.json
# Auth: --token flag or $env.CHECKS_API_TOKEN

const CLIENT = {
  base_url: "https://api.truora.com"
  token_env_var: "CHECKS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: truora-api-key, in: header, header_name: Truora-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.truora.com"] }
def auth-scheme-completer [] { ["truora-api-key"] }

# Completers for enum parameters
def country-completer [] { ["bo" "br" "cl" "co" "cr" "do" "ec" "gt" "mx" "pa" "pe" "sv" "ve"] }
def document-type-completer [] { ["civil-registration" "curp" "diplomatic-id" "dni" "driver-license" "dui" "escrow" "foreign-id" "foreign-societies" "foreigner-card" "general-registration" "identity-card" "individual-registration" "license-plate" "military-card" "name" "national-id" "nis" "nit" "nuip" "passport" "pep" "professional-card" "query" "ruc" "rui" "rut"] }
def reason-completer [] { ["absences" "aggressive-behaviour" "confidentiality-breach" "drug-dealer" "drug-possession" "drunk" "fights" "good-reputation" "identity-fraud" "rape" "sexual-harassment" "tardiness" "theft"] }
def country-completer-1 [] { ["ALL" "AR" "BR" "CL" "CO" "CR" "EC" "MX" "PE"] }
def region-completer [] { ["AC" "AL" "AM" "AP" "BA" "CE" "DF" "ES" "GO" "MA" "MG" "MS" "MT" "PA" "PB" "PE" "PI" "PR" "RJ" "RN" "RO" "RR" "RS" "SC" "SE" "SP" "TO"] }
def type-completer [] { ["company" "custom_type_name" "person" "vehicle"] }
def truora-priority-completer [] { ["high" "low" "medium"] }
def country-completer-2 [] { ["ALL" "BR" "CL" "CO" "CR" "EC" "MX" "PE"] }
def status-completer [] { ["disabled" "enabled"] }
def event-type-completer [] { ["all" "check" "continuous_check"] }
def subscriber-language-completer [] { ["af" "ar" "ca" "cs" "da" "de" "el" "en" "es" "fi" "fr" "he" "hi" "hr" "hu" "id" "it" "ja" "ko" "ms" "nb" "nl" "pl" "pr-BR" "pt" "ro" "ru" "sv" "th" "tl" "tr" "vi" "zh" "zh-CN" "zh-HK"] }
def subscriber-type-completer [] { ["email" "web"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    report-behavior: "record<behavior: table<birth_date: string, country: any, creation_date: string, document_id: string, document_type: any, email: string, feedback_date: string, first_name: string, last_name: string, phone_number: string, reason: string>, self: string>"
    list-checks: "record<checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string>"
    create-check: "record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string>"
    get-health-dashboard: "table<data_sets: list<string>, database_id: string, database_name: string, hourly_status: list<string>>"
    get-check: "record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string>"
    list-check-details: "record<details: table<check_id: string, data_set: string, database_name: string, group: any, id: string, result: any, score: float, tables: list>, next: string, self: string>"
    list-score-configs: "record<score_configs: table<ScoreConfigByCountry: list>>"
    create-score-config: "record<ScoreConfigByCountry: table<data_set: string, weight: string>>"
    list-continuous-checks: "record<continuous_checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string>"
    create-continuous-check: "record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>"
    get-continuous-check: "record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>"
    update-continuous-check: "record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>"
    get-v1-continuous-checks-continuous-check-id-history: "record<history: table<dataset_score_changes: float, score_changes: list>, next: string, self: string>"
    list-hook: "record<hooks: table<actions: list, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>, next: string, self: string, signing_key: string>"
    create-hook: "record<actions: list<string>, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>"
    delet-hook: "string"
    update-hook: "record<actions: list<string>, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>"
    list-reports: "record<next: string, reports: table<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>"
    create-report: "record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>"
    get-report: "record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>"
    batch-upload: "record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["report-behavior" "list-checks" "create-check" "get-health-dashboard" "get-check" "list-check-details" "get-pdf" "create-pdf" "delete-custom-type" "list-score-configs" "create-score-config" "update-custom-type" "list-continuous-checks" "create-continuous-check" "get-continuous-check" "update-continuous-check" "get-v1-continuous-checks-continuous-check-id-history" "list-hook" "create-hook" "delet-hook" "update-hook" "list-reports" "create-report" "get-report" "batch-upload" "commands"] | sort) } | get name | first)
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

# Report Behavior
#
# POST /v1/behavior
# Returns: record<behavior: table<birth_date: string, country: any, creation_date: string, document_id: string, document_type: any, email: string, feedback_date: string, first_name: string, last_name: string, phone_number: string, reason: string>, self: string>
# operationId: reportBehavior
export def "report-behavior" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  birth_date: string # Birth date of reported person (format: date-time)
  country: any@country-completer # Document country
  document_id: string # Person document ID
  document_type: any@document-type-completer # Document type associated with the background check
  email: string # Reported person e-mail
  feedback_date: string # Behavior report date (format: date-time)
  first_name: string # Person first name
  last_name: string # Person last name
  --phone-number: string # Phone number of the reported person
  reason: any@reason-completer # Report reason
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/behavior"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: birth_date, var: birth_date}, {name: country, var: country}, {name: document_id, var: document_id}, {name: document_type, var: document_type}, {name: email, var: email}, {name: feedback_date, var: feedback_date}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: phone_number, var: phone_number}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    birth_date: $birth_date, country: $country, document_id: $document_id, document_type: $document_type, email: $email, feedback_date: $feedback_date, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Checks
#
# GET /v1/checks
# Returns: record<checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string>
# operationId: listChecks
export def "list-checks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start key value for the pagination
  --report-id: string # Report id checks to be returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/checks"
    query: [{name: start_key, var: start_key}, {name: report_id, var: report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    start_key: $start_key, report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a background check
#
# POST /v1/checks
# Returns: record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string>
# operationId: createCheck
export def "create-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --truora-priority: string@truora-priority-completer # Describes the background check priority. The amount of high priority checks is limited by country. Medium priority is used by default
  --birth-certificate: string # Person birth certificate
  --company-name: string # Company name "Don't forget this required field to complete background checks in Brazil"
  country: string@country-completer-1 # Document country
  --date-of-birth: string # Person birthdate. This date is used to get some additional information about a person and to filter homonyms in some cases. YYYY-MM-DD format, Required for complete background checks in Brazil (format: date)
  --diplomatic-id: string # Diplomatic ID
  --driver-license: string # Driver's license number
  --escrow: string # Colombian escrow
  --first-name: string # Person or entity first name. If the document type and number are not provided, the report might include homonyms. Required when searching by first name, Required in order to get complete background checks in Brazil
  --force-creation: oneof<nothing, bool> # Forces a new background check creation when true. Reuses recently created background checks otherwise
  --foreign-id: string # Person foreign ID
  --issue-date: string # Person document issue date in "YYYY-mm-dd" format (e.g. 2008-12-31) . This date is used to get some additional information about a person in some cases (format: date)
  --last-name: string # Person or entity last name. If the document type and number are not provided, the report might include homonyms. Required when searching by last name. Required in order to get complete background checks in Brazil
  --license-plate: string # Vehicle license plate
  --national-id: string # National ID
  --native-country: string # Country of birth
  --owner-document-id: string # National ID of the vehicle owner
  --owner-document-type: string # National ID, foreign ID, or tax ID
  --passport: string # Person passport
  --payment-date: string # Payment day of a vehicle circulation permit (Chile only) (format: date)
  --pep: string # ID for Venezuelans working in Colombia
  --phone-number: string # Person phone number. Required by law to notify the person their background is being checked
  --professional-card: string # Professional ID card
  --ptp: string # ID for Venezuelans working in Peru
  --region: string@region-completer # Region where the background is to be checked in addition to the region where the person is from. By default, background checks in Brazil are performed in the region where the person is from. Required for Brazil only. Allowed values are: DF: Distrito Federal, AC: Acre, AL: Alagoas, AP: Amapá, AM: Amazonas, BA: Bahía, CE: Ceará, ES: Espírito Santo, GO: Goiás, MA: Maranhão, MT: Mato Grosso, MS: Mato Grosso do Sul, MG: Minas Gerais, PA: Pará, PB: Paraíba, PR: Paraná, PE: Pernambuco, PI: Piauí, RJ: Río de Janeiro, RN: Río Grande do Norte, RS: Río Grande do Sul, RO: Rondônia, RR: Roraima, SC: Santa Catarina, SP: São Paulo, SE: Sergipe, TO : Tocantins.
  --report-id: string # Report ID the background check will be inserted into
  --state-id: string # Used for the RG (Registro Geral) identification in Brazil. This identification has different formats according to the state that issues the document. It can have numbers and letters but other characters (- * , . ) are omitted, Required in order to get complete background checks in Brazil
  --tax-id: string # Company ID used for tax payments
  type: string@type-completer # Background check type
  --user-authorized: oneof<nothing, bool> # Indicates whether the person subject to the validation authorized the validation. Must be true in order to proceed [Required for API key V1 or later]
  --vehicle-id: string # Vehicle license plate
  --verification-code: string # Verification code registered for criminal records in Peru only
  --watch: string # Indicates whether the check score is to be periodically revised and its frequency. It can be daily, weekly, monthly, yearly or have a custom frequency written as a number accompanied by d: day, w: week, m: month, y: year for instance: 3d: every three days, 2w: every two weeks. Ignore this field if the check is only to be performed once
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/checks"
    header: [{name: Truora-Priority, var: truora_priority}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: birth_certificate, var: birth_certificate}, {name: company_name, var: company_name}, {name: country, var: country}, {name: date_of_birth, var: date_of_birth}, {name: diplomatic_id, var: diplomatic_id}, {name: driver_license, var: driver_license}, {name: escrow, var: escrow}, {name: first_name, var: first_name}, {name: force_creation, var: force_creation}, {name: foreign_id, var: foreign_id}, {name: issue_date, var: issue_date}, {name: last_name, var: last_name}, {name: license_plate, var: license_plate}, {name: national_id, var: national_id}, {name: native_country, var: native_country}, {name: owner_document_id, var: owner_document_id}, {name: owner_document_type, var: owner_document_type}, {name: passport, var: passport}, {name: payment_date, var: payment_date}, {name: pep, var: pep}, {name: phone_number, var: phone_number}, {name: professional_card, var: professional_card}, {name: ptp, var: ptp}, {name: region, var: region}, {name: report_id, var: report_id}, {name: state_id, var: state_id}, {name: tax_id, var: tax_id}, {name: type, var: type}, {name: user_authorized, var: user_authorized}, {name: vehicle_id, var: vehicle_id}, {name: verification_code, var: verification_code}, {name: watch, var: watch}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    truora_priority: $truora_priority, birth_certificate: $birth_certificate, company_name: $company_name, country: $country, date_of_birth: $date_of_birth, diplomatic_id: $diplomatic_id, driver_license: $driver_license, escrow: $escrow, first_name: $first_name, force_creation: $force_creation, foreign_id: $foreign_id, issue_date: $issue_date, last_name: $last_name, license_plate: $license_plate, national_id: $national_id, native_country: $native_country, owner_document_id: $owner_document_id, owner_document_type: $owner_document_type, passport: $passport, payment_date: $payment_date, pep: $pep, phone_number: $phone_number, professional_card: $professional_card, ptp: $ptp, region: $region, report_id: $report_id, state_id: $state_id, tax_id: $tax_id, type: $type, user_authorized: $user_authorized, vehicle_id: $vehicle_id, verification_code: $verification_code, watch: $watch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Health Dashboard
#
# GET /v1/checks/health
# Returns: table<data_sets: list<string>, database_id: string, database_name: string, hourly_status: list<string>>
# operationId: GetHealthDashboard
export def "get-health-dashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country in ISO 3166, uppercase
  --unix-timestamp-seconds: string # Unix timestamp in seconds. Send a day timestamp to view the database hourly status for that day or send the current time to know the current database status
  --unixtimezone-offset-seconds: string # Offset between the local time and the UTC time in seconds. (e.g., Colombia is at UTC -18000 seconds)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/checks/health"
    query: [{name: country, var: country}, {name: unixTimestampSeconds, var: unix_timestamp_seconds}, {name: unixtimezoneOffsetSeconds, var: unixtimezone_offset_seconds}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    country: $country, unix_timestamp_seconds: $unix_timestamp_seconds, unixtimezone_offset_seconds: $unixtimezone_offset_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Background Check
#
# GET /v1/checks/{check_id}
# Returns: record<check: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, details: string, self: string>
# operationId: getCheck
export def "get-check" [
  check_id: string
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
    path: "/v1/checks/{check_id}"
    path_params: [{name: check_id, var: check_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    check_id: $check_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Check Details
#
# GET /v1/checks/{check_id}/details
# Returns: record<details: table<check_id: string, data_set: string, database_name: string, group: any, id: string, result: any, score: float, tables: list>, next: string, self: string>
# operationId: listCheckDetails
export def "list-check-details" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start key value for the pagination
  --lang: string # This parameter is used to specify the language wanted for details, if not specified details will come in their original language.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/checks/{check_id}/details"
    path_params: [{name: check_id, var: check_id}]
    query: [{name: start_key, var: start_key}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    check_id: $check_id, start_key: $start_key, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get PDF
#
# GET /v1/checks/{check_id}/pdf
# operationId: getPDF
export def "get-pdf" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Used to specify the language for the PDF, if not specified the PDF will be downloaded in Spanish.
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/checks/{check_id}/pdf"
    path_params: [{name: check_id, var: check_id}]
    query: [{name: lang, var: lang}]
    accept: [PDF]
    ok: [200]
    auth: truora-api-key
  } {
    check_id: $check_id, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create PDF
#
# POST /v1/checks/{check_id}/pdf
# operationId: CreatePDF
export def "create-pdf" [
  check_id: string
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
    path: "/v1/checks/{check_id}/pdf"
    path_params: [{name: check_id, var: check_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    check_id: $check_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Custom Type
#
# DELETE /v1/config
# operationId: DeleteCustomType
export def "delete-custom-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Name of the custom type to be deleted (required)
  --country: string@country-completer-2 # Country where the custom type is valid
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/config"
    query: [{name: type, var: type, required: true}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    type: $type, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Score Configurations
#
# GET /v1/config
# Returns: record<score_configs: table<ScoreConfigByCountry: list>>
# operationId: listScoreConfigs
export def "list-score-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # The key to start the pagination
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/config"
    query: [{name: start_key, var: start_key}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    start_key: $start_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Score Configurations
#
# POST /v1/config
# Returns: record<ScoreConfigByCountry: table<data_set: string, weight: string>>
# operationId: createScoreConfig
export def "create-score-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string@country-completer-1 # Country where this set of rules applies. Use "all" if the check type searches by name by relying on international databases
  --dataset-affiliations-and-insurances: float # Affiliation and insurance weight for score calculation. From 0 to 1 (format: float)
  --dataset-alert-in-media: float # Alert in media weight for score calculation. From 0 to 1 (format: float)
  --dataset-business-background: float # Business background weight for score calculation. From 0 to 1 (format: float)
  --dataset-criminal-record: float # Criminal record weight for score calculation. From 0 to 1 (format: float)
  --dataset-driving-licenses: float # Driving license weight for score calculation. From 0 to 1 (format: float)
  --dataset-international-background: float # International background weight for score calculation. From 0 to 1 (format: float)
  --dataset-legal-background: float # Legal background weight for score calculation. From 0 to 1 (format: float)
  --dataset-personal-identity: float # Personal identity weight for score calculation. From 0 to 1 (format: float)
  --dataset-professional-background: float # Professional background weight for score calculation. From 0 to 1 (format: float)
  --dataset-taxes-and-finances: float # Taxes and financial background weight for score calculation. From 0 to 1 (format: float)
  --dataset-traffic-fines: float # Traffic fines weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-information: float # Vehicle information weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-permits: float # Vehicle certificate background weight for score calculation. From 0 to 1 (format: float)
  type: string # Score configuration name. It cannot be person, vehicle, or company
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/config"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: country, var: country}, {name: dataset_affiliations_and_insurances, var: dataset_affiliations_and_insurances}, {name: dataset_alert_in_media, var: dataset_alert_in_media}, {name: dataset_business_background, var: dataset_business_background}, {name: dataset_criminal_record, var: dataset_criminal_record}, {name: dataset_driving_licenses, var: dataset_driving_licenses}, {name: dataset_international_background, var: dataset_international_background}, {name: dataset_legal_background, var: dataset_legal_background}, {name: dataset_personal_identity, var: dataset_personal_identity}, {name: dataset_professional_background, var: dataset_professional_background}, {name: dataset_taxes_and_finances, var: dataset_taxes_and_finances}, {name: dataset_traffic_fines, var: dataset_traffic_fines}, {name: dataset_vehicle_information, var: dataset_vehicle_information}, {name: dataset_vehicle_permits, var: dataset_vehicle_permits}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    country: $country, dataset_affiliations_and_insurances: $dataset_affiliations_and_insurances, dataset_alert_in_media: $dataset_alert_in_media, dataset_business_background: $dataset_business_background, dataset_criminal_record: $dataset_criminal_record, dataset_driving_licenses: $dataset_driving_licenses, dataset_international_background: $dataset_international_background, dataset_legal_background: $dataset_legal_background, dataset_personal_identity: $dataset_personal_identity, dataset_professional_background: $dataset_professional_background, dataset_taxes_and_finances: $dataset_taxes_and_finances, dataset_traffic_fines: $dataset_traffic_fines, dataset_vehicle_information: $dataset_vehicle_information, dataset_vehicle_permits: $dataset_vehicle_permits, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Custom Type
#
# PUT /v1/config
# operationId: UpdateCustomType
export def "update-custom-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string@country-completer-1 # Country where this set of rules applies. Use "all" if the check type searches by name by relying on international databases
  --dataset-affiliations-and-insurances: float # Affiliation and insurance weight for score calculation. From 0 to 1 (format: float)
  --dataset-alert-in-media: float # Alert in media weight for score calculation. From 0 to 1 (format: float)
  --dataset-business-background: float # Business background weight for score calculation. From 0 to 1 (format: float)
  --dataset-criminal-record: float # Criminal record weight for score calculation. From 0 to 1 (format: float)
  --dataset-driving-licenses: float # Driving license weight for score calculation. From 0 to 1 (format: float)
  --dataset-international-background: float # International background weight for score calculation. From 0 to 1 (format: float)
  --dataset-legal-background: float # Legal background weight for score calculation. From 0 to 1 (format: float)
  --dataset-personal-identity: float # Personal identity weight for score calculation. From 0 to 1 (format: float)
  --dataset-professional-background: float # Professional background weight for score calculation. From 0 to 1 (format: float)
  --dataset-taxes-and-finances: float # Taxes and financial background weight for score calculation. From 0 to 1 (format: float)
  --dataset-traffic-fines: float # Traffic fines weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-information: float # Vehicle information weight for score calculation. From 0 to 1 (format: float)
  --dataset-vehicle-permits: float # Vehicle certificate background weight for score calculation. From 0 to 1 (format: float)
  type: string # Score configuration name. It cannot be person, vehicle, or company
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/config"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: country, var: country}, {name: dataset_affiliations_and_insurances, var: dataset_affiliations_and_insurances}, {name: dataset_alert_in_media, var: dataset_alert_in_media}, {name: dataset_business_background, var: dataset_business_background}, {name: dataset_criminal_record, var: dataset_criminal_record}, {name: dataset_driving_licenses, var: dataset_driving_licenses}, {name: dataset_international_background, var: dataset_international_background}, {name: dataset_legal_background, var: dataset_legal_background}, {name: dataset_personal_identity, var: dataset_personal_identity}, {name: dataset_professional_background, var: dataset_professional_background}, {name: dataset_taxes_and_finances, var: dataset_taxes_and_finances}, {name: dataset_traffic_fines, var: dataset_traffic_fines}, {name: dataset_vehicle_information, var: dataset_vehicle_information}, {name: dataset_vehicle_permits, var: dataset_vehicle_permits}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    country: $country, dataset_affiliations_and_insurances: $dataset_affiliations_and_insurances, dataset_alert_in_media: $dataset_alert_in_media, dataset_business_background: $dataset_business_background, dataset_criminal_record: $dataset_criminal_record, dataset_driving_licenses: $dataset_driving_licenses, dataset_international_background: $dataset_international_background, dataset_legal_background: $dataset_legal_background, dataset_personal_identity: $dataset_personal_identity, dataset_professional_background: $dataset_professional_background, dataset_taxes_and_finances: $dataset_taxes_and_finances, dataset_traffic_fines: $dataset_traffic_fines, dataset_vehicle_information: $dataset_vehicle_information, dataset_vehicle_permits: $dataset_vehicle_permits, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all continuous checks
#
# GET /v1/continuous-checks
# Returns: record<continuous_checks: table<birth_certificate: string, check_id: string, company_summary: record, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list, status: string, statuses: list, summary: record, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record, wrong_inputs: list>, next: string, self: string>
# operationId: ListContinuousChecks
export def "list-continuous-checks" [
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
    path: "/v1/continuous-checks"
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a continuous check that will run background checks recurrently according to the frequency provided.
#
# POST /v1/continuous-checks
# Returns: record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>
# operationId: createContinuousCheck
export def "create-continuous-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-id: string # Background checks to be processed recurrently
  --frequency: string # Time between background checks. It can be daily, weekly, monthly, yearly or have a custom frequency written as a number accompanied by d: day, w: week, m: month, y: year for instance: 3d: every three days, 2w: every two weeks
  --status: string # Indicates whether the background checks must be processed recurrently (enabled | disabled)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/continuous-checks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: check_id, var: check_id}, {name: frequency, var: frequency}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    check_id: $check_id, frequency: $frequency, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists history associated with a Check. It can be paginated
#
# GET /v1/continuous-checks/{continuous_check_id}
# Returns: record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>
# operationId: GetContinuousCheck
export def "get-continuous-check" [
  continuous_check_id: float
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
    path: "/v1/continuous-checks/{continuous_check_id}"
    path_params: [{name: continuous_check_id, var: continuous_check_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    continuous_check_id: $continuous_check_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a continuous check
#
# PUT /v1/continuous-checks/{continuous_check_id}
# Returns: record<ContinuousCheckID: string, ContinuousCheckStatus: string, CreationDate: string, Enabled: bool, Frequency: string, History: record<changes: list<record>, check_id: string, continuous_check_id: string, creation_date: string, previous_check_id: string>, LastCheckID: string, NextRunDate: string, OriginalCheck: record<birth_certificate: string, check_id: string, company_summary: record<names_found: list>, country: string, creation_date: string, date_of_birth: string, diplomatic_id: string, driver_license: string, first_name: string, foreign_id: string, homonym_probability: float, homonym_score: float, homonym_scores: list<record>, id_score: float, issue_date: string, last_name: string, license_plate: string, national_id: string, native_country: string, owner_document_id: string, owner_document_type: string, passport: string, payment_date: string, pep: string, phone_number: string, professional_card: string, ptp: string, region: string, report_id: string, score: float, scores: list<record>, status: string, statuses: list<record>, summary: record<date_of_birth: string, death_date: string, drivers_license: string, gender: string, identity_status: string, names_found: list, nss: string, rfc: string>, tax_id: string, type: any, update_date: string, vehicle_id: string, vehicle_summary: record<capacity: int, color: string, license_plate: string, manufacturer: string, model: string, number_of_doors: int, obligatory_insurance_expiration_date: string, obligatory_insurance_status: string, service_type: string, vehicle_category: string, vehicle_id: string, vehicle_type: string, year: int>, wrong_inputs: list<record>>, UpdateDate: string>
# operationId: UpdateContinuousCheck
export def "update-continuous-check" [
  continuous_check_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  frequency: string # Time between background checks
  status: string@status-completer # Indicates whether the background checks must be processed recurrently
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/continuous-checks/{continuous_check_id}"
    path_params: [{name: continuous_check_id, var: continuous_check_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: frequency, var: frequency}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    continuous_check_id: $continuous_check_id, frequency: $frequency, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists background check logs. It can be paginated
#
# GET /v1/continuous-checks/{continuous_check_id}/history
# Returns: record<history: table<dataset_score_changes: float, score_changes: list>, next: string, self: string>
export def "get-v1-continuous-checks-continuous-check-id-history" [
  continuous_check_id: string
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
    path: "/v1/continuous-checks/{continuous_check_id}/history"
    path_params: [{name: continuous_check_id, var: continuous_check_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    continuous_check_id: $continuous_check_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all hooks
#
# GET /v1/hooks
# Returns: record<hooks: table<actions: list, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>, next: string, self: string, signing_key: string>
# operationId: listHook
export def "list-hook" [
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
    path: "/v1/hooks"
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a hook subscription
#
# POST /v1/hooks
# Returns: record<actions: list<string>, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>
# operationId: createHook
export def "create-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list<string> # Actions you want to be notified. Possible inputs are created, started, and finished or any combination of those three
  event_type: string@event-type-completer # The entity events the client wants to subscribe
  --status: string@status-completer # indicates whether the hook is active or not. enabled by default
  --subscriber-address: string # Email address where the notification is to be sent. Required if subscriber_type was set to email
  --subscriber-language: string@subscriber-language-completer # Language for the notification to be sent
  --subscriber-name: string # Name of the person to be notified
  subscriber_type: string@subscriber-type-completer # A platform with an endpoint ready to process the information
  --subscriber-url: string # URL where the notification is to be sent. Required only if subscriber_type is set to web
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/hooks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: actions, var: actions}, {name: event_type, var: event_type}, {name: status, var: status}, {name: subscriber_address, var: subscriber_address}, {name: subscriber_language, var: subscriber_language}, {name: subscriber_name, var: subscriber_name}, {name: subscriber_type, var: subscriber_type}, {name: subscriber_url, var: subscriber_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    actions: $actions, event_type: $event_type, status: $status, subscriber_address: $subscriber_address, subscriber_language: $subscriber_language, subscriber_name: $subscriber_name, subscriber_type: $subscriber_type, subscriber_url: $subscriber_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes hook
#
# DELETE /v1/hooks/{hook_id}
# Returns: string
# operationId: deletHook
export def "delet-hook" [
  hook_id: string
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
    path: "/v1/hooks/{hook_id}"
    path_params: [{name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates hook
#
# PUT /v1/hooks/{hook_id}
# Returns: record<actions: list<string>, event_type: string, signing_key: string, status: string, subscriber_type: string, subscriber_url: string>
# operationId: updateHook
export def "update-hook" [
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list<string> # Actions you want to be notified. Possible inputs are created, started, and finished or any combination of those three
  event_type: string@event-type-completer # The entity events the client wants to subscribe
  --status: string@status-completer # indicates whether the hook is active or not. enabled by default
  --subscriber-address: string # Email address where the notification is to be sent. Required if subscriber_type was set to email
  --subscriber-language: string@subscriber-language-completer # Language for the notification to be sent
  --subscriber-name: string # Name of the person to be notified
  subscriber_type: string@subscriber-type-completer # A platform with an endpoint ready to process the information
  --subscriber-url: string # URL where the notification is to be sent. Required only if subscriber_type is set to web
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/hooks/{hook_id}"
    path_params: [{name: hook_id, var: hook_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: actions, var: actions}, {name: event_type, var: event_type}, {name: status, var: status}, {name: subscriber_address, var: subscriber_address}, {name: subscriber_language, var: subscriber_language}, {name: subscriber_name, var: subscriber_name}, {name: subscriber_type, var: subscriber_type}, {name: subscriber_url, var: subscriber_url}]}
    accept: ["application/x-www-form-urlencoded"]
    ok: [200]
    auth: truora-api-key
  } {
    hook_id: $hook_id, actions: $actions, event_type: $event_type, status: $status, subscriber_address: $subscriber_address, subscriber_language: $subscriber_language, subscriber_name: $subscriber_name, subscriber_type: $subscriber_type, subscriber_url: $subscriber_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Reports
#
# GET /v1/reports
# Returns: record<next: string, reports: table<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>
# operationId: listReports
export def "list-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-key: string # Start value for pagination.
  --username: string # filter reports created by the specified username
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/reports"
    query: [{name: start_key, var: start_key}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    start_key: $start_key, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Report
#
# POST /v1/reports
# Returns: record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>
# operationId: createReport
export def "create-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Report name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/reports"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: truora-api-key
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Report
#
# GET /v1/reports/{report_id}
# Returns: record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>
# operationId: getReport
export def "get-report" [
  report_id: string
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
    path: "/v1/reports/{report_id}"
    path_params: [{name: report_id, var: report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch Upload
#
# POST /v1/reports/{report_id}/upload
# Returns: record<checks: string, report: record<created_by: string, created_checks_count: int, creation_date: string, has_data: bool, id: string, invalid_checks_count: int, name: string, size: int, update_date: string>, self: string>
# operationId: batchUpload
export def "batch-upload" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: list<string> # Uploaded file name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/reports/{report_id}/upload"
    path_params: [{name: report_id, var: report_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: truora-api-key
  } {
    report_id: $report_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
