# Auto-generated client for Apacta v0.0.42
# Source: https://api.apis.guru/v2/specs/apacta.com/0.0.42/openapi.json
# Auth: --token flag or $env.APACTA_TOKEN

const CLIENT = {
  base_url: "https://app.apacta.com/api/v1"
  token_env_var: "APACTA_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-auth-token, in: header, header_name: X-Auth-Token, prefix: ""}
    {name: query-api_token, in: query, header_name: api_token, prefix: ""}
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

def base-url-completer [] { ["https://app.apacta.com/api/v1"] }
def auth-scheme-completer [] { ["x-auth-token" "query-api_token"] }

# Completers for enum parameters
def due-date-completer [] { ["exceeded" "valid"] }
def status-completer [] { ["approved" "expired_subscription"] }
def projects-completer [] { ["[project1, project2, project3]" "all" "none"] }
def extended-completer [] { ["false" "true"] }
def is-draft-completer [] { ["0" "1"] }
def is-offer-completer [] { ["0" "1"] }
def is-locked-completer [] { ["0" "1"] }
def is-fixed-price-completer [] { ["0" "1"] }
def billing-cysle-completer [] { ["daily" "hourly" "weekly"] }
def status-completer-1 [] { ["accepted" "draft" "rejected"] }
def variant-type-completer [] { ["expense_line" "vendor_product"] }
def status-completer-2 [] { ["awaiting" "expired" "failed" "fresh"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-activities: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, hex_code: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-activities: "record<data: list<string>, success: bool>"
    delete-activities-bulk-delete: "record<data: list<string>, success: bool>"
    delete-activities-activity-id: "record<data: list<string>, success: bool>"
    put-activities-activity-id: "record<data: list<string>, success: bool>"
    get-cities: "record<data: table<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-cities-city-id: "record<data: record<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, success: bool>"
    get-clocking-records: "record<data: table<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-clocking-records: "record<data: record<id: string>, success: bool>"
    post-clocking-records-checkout: "record<success: bool>"
    delete-clocking-records-clocking-record-id: "record<data: list<string>, success: bool>"
    get-clocking-records-clocking-record-id: "record<data: record<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, success: bool>"
    put-clocking-records-clocking-record-id: "record<data: list<record>, success: bool>"
    get-companies: "record<data: table<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-companies-subscription-self-service: "record<data: record<subscription_self_service_url: string>, success: bool>"
    get-companies-company-id: "record<data: record<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, success: bool>"
    get-companies-company-id-companies-integration-feature-settings: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>"
    post-companies-company-id-companies-integration-feature-settings: "record<data: record<id: string>, success: bool>"
    get-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>"
    put-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>"
    get-companies-company-id-form-templates: "record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    delete-companies-company-id-form-templates-form-template-id: "record<data: list<string>, success: bool>"
    get-companies-company-id-form-templates-form-template-id: "record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-companies-company-id-integration-feature-settings: "record<data: table<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-companies-company-id-integration-feature-settings-integration-feature-setting-id: "record<data: record<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, success: bool>"
    get-companies-company-id-integration-settings: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-companies-company-id-integration-settings: "record<data: record<id: string>, success: bool>"
    delete-companies-company-id-integration-settings-companies-integration-setting-id: "record<data: list<string>, success: bool>"
    get-companies-company-id-integration-settings-companies-integration-setting-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, success: bool>"
    put-companies-company-id-integration-settings-companies-integration-setting-id: "record<data: list<string>, success: bool>"
    delete-companies-company-id-price-margins-price-margins-id: "record<data: list<string>, success: bool>"
    get-companies-company-id-price-margins-price-margins-id: "record<data: table<amount_from: float, amount_to: float, company_id: string, created: string, deleted: string, id: string, modified: string, percentage_ratio: float, ratio: float, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-companies-company-id-price-margins-price-margins-id: "record<data: record<id: string>, success: bool>"
    get-compaies-vendors-list: "record<data: table<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    add-companies-vendor: "record<data: record<id: string>, success: bool>"
    bulk-companies-vendors: "record<data: list<string>, success: bool>"
    delete-companies-vendors-companies-vendor-id: "record<data: list<string>, success: bool>"
    get-companies-vendor: "record<data: record<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, success: bool>"
    edit-companies-vendor: "record<data: list<record>, success: bool>"
    get-companies-vendors-expense-statistics: "record<data: table<last_month: list, thirty_days: list, vendor_id: string>>"
    get-compay-settings-list: "record<data: record<company_settings_category_id: string, created: string, created_by_id: string, default_value: string, deleted: string, description: string, feature_id: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, options: string, placement: int, type: string>, success: bool>"
    get-contact-custom-field-attributes: "record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-contact-custom-field-attributes-contact-custom-field-attribute-id: "record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>"
    get-contact-types: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-contact-types-contact-type-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>"
    get-contacts: "record<data: table<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-contacts: "record<data: record<id: string>, success: bool>"
    bulk-delete-contacts: "record<data: list<string>, success: bool>"
    delete-contacts-contact-id: "record<data: list<string>, success: bool>"
    get-contacts-contact-id: "record<data: record<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, success: bool>"
    put-contacts-contact-id: "record<data: list<record>, success: bool>"
    get-contacts-contact-id-contact-custom-field-values: "record<data: table<contact_custom_field_attribute_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-contact-persons-list: "record<data: table<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    add-contact-person: "record<data: record<id: string>, success: bool>"
    delete-contacts-contact-id-contact-persons-contact-person-id: "record<data: list<string>, success: bool>"
    get-contact-person: "record<data: record<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, success: bool>"
    edit-contact-person: "record<data: list<record>, success: bool>"
    get-countries: "record<data: table<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-countries-country-id: "record<data: record<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, success: bool>"
    get-currencies: "record<data: table<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-currencies-currency-id: "record<data: record<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, success: bool>"
    get-driving-types: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-driving-types: "record<data: record<id: string>, success: bool>"
    bulk-delete-driving-types: "record<data: list<string>, success: bool>"
    delete-driving-types-driving-type-id: "record<data: list<string>, success: bool>"
    get-driving-types-driving-type-id: "record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>"
    put-driving-types-driving-type-id: "record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>"
    get-employee-hours: "record<data: table<form_date: string, form_id: string, project_name: string, total_hours: int, working_description: string, working_description_full: string>, success: bool>"
    get-events: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-events: "record<data: record<id: string>, success: bool>"
    get-events-is-user-free: "record<result: bool, success: bool>"
    delete-events-event-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>"
    get-events-event-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>"
    put-events-event-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>"
    get-expense-files: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, expense_id: string, file: string, file_extension: string, file_original_name: string, file_size: string, file_type: string, file_url: string, id: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-expense-files: "record<data: record<id: string>, success: bool>"
    delete-expense-files-expense-file-id: "record<data: list<string>, success: bool>"
    get-expense-files-expense-file-id: "record<data: list<string>, success: bool>"
    put-expense-files-expense-file-id: "record<data: record, success: bool>"
    get-expense-lines: "record<data: table<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-expense-lines: "record<data: record<id: string>, success: bool>"
    delete-expense-lines-expense-line-id: "record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>"
    get-expense-lines-expense-line-id: "record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>"
    put-expense-lines-expense-line-id: "record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>"
    get-expenses: "record<data: table<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-expenses: "record<data: record<id: string>, success: bool>"
    bulk-delete-expenses: "record<data: list<string>, success: bool>"
    get-expenses-highest-amount: "record<data: table<highest_amount: float>, success: bool>"
    send-emails-expenses: "record<data: list<string>, success: bool>"
    delete-expenses-expense-id: "record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>"
    get-expenses-expense-id: "record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>"
    put-expenses-expense-id: "record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>"
    get-expenses-expense-id-original-files: "record<success: bool>"
    get-expenses-expense-id-original-files-file-id: "record<success: bool>"
    get-financial-statistics: "record<data: record<invoicedAmount: float, invoicedWorkingHours: string, notInvoicedAmount: float, notInvoicedWorkingHours: string, productsCosts: float, productsSales: float, rentalsCosts: float, rentalsSales: float, totalCosts: float, totalSales: float, workTimeCosts: float, workTimeSales: float>, success: bool>"
    get-expenses-sales-price: "record<expensesSalesPrice: float>"
    get-invoiced-amount: "record<invoicedAmount: float>"
    get-margin: "record<margin: float>"
    get-material-rentals-cost-price: "record<materialRentalsCostPrice: float>"
    get-financial-statistics-overview: "record<data: record<expensesSalesPrice: float, invoicedAmount: float, margin: float, materialRentalsCostPrice: float, productsCostPrice: float, totalWorkingHours: string>, success: bool>"
    get-products-cost-price: "record<productsCostPrice: float>"
    get-financial-statistics-working-hours: "record<normalWorkingHours: string, timeEntries: table<id: string, name: string, total: string>, totalWorkingHours: string>"
    get-form-field-types: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-form-field-types-form-field-type-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>"
    post-form-fields: "record<data: record<id: string>, success: bool>"
    get-form-fields-form-field-id: "record<data: record<comment: string, content_value: string, created: string, created_by_id: string, deleted: string, file_id: string, form_field_type_id: string, form_id: string, form_template_field_id: string, id: string, modified: string, placement: int>, success: bool>"
    get-form-templates: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-form-templates-form-template-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, success: bool>"
    get-forms: "record<data: table<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-forms: "record<data: record<id: string>, success: bool>"
    get-forms-undelete-form-id: "record<data: list<string>, success: bool>"
    get-forms-view-time-form-pdf-form-id: "record<data: list<string>, success: bool>"
    get-forms-form-id: "record<data: record<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, success: bool>"
    get-integrations-list: "record<status: string, success: bool>"
    post-integrations-billys-authenticate: "record<accessToken: string>"
    get-integrations-contacts-sync: "record<status: string, success: bool>"
    get-integrations-products-sync: "record<success: bool>"
    get-integrations-view: "record<status: string, success: bool>"
    get-invoice-line-text-template: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-invoice-line-text-template: "record<data: record<id: string>, success: bool>"
    delete-invoice-line-text-template-invoice-line-text-template-id: "record<data: list<string>, success: bool>"
    get-invoice-line-text-template-invoice-line-text-template-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, success: bool>"
    post-invoice-line-text-template-invoice-line-text-template-id: "record<data: list<string>, success: bool>"
    post-invoice-line-texts: "record<data: record<id: string>, success: bool>"
    post-invoice-line-texts-invoice-line-text-id: "record<data: list<string>, success: bool>"
    get-invoice-lines: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-invoice-lines: "record<data: record<id: string>, success: bool>"
    delete-invoice-lines-invoice-line-id: "record<data: list<record>, success: bool>"
    get-invoice-lines-invoice-line-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, success: bool>"
    put-invoice-lines-invoice-line-id: "record<data: list<record>, success: bool>"
    get-invoices: "record<data: table<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-invoices: "record<data: record<id: string>, success: bool>"
    bulk-delete-invoices: "record<data: list<string>, success: bool>"
    get-invoices-vat-options: "record<success: bool>"
    delete-invoices-invoice-id: "record<data: list<record>, success: bool>"
    get-invoices-invoice-id: "record<data: record<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, success: bool>"
    put-invoices-invoice-id: "record<data: list<record>, success: bool>"
    post-invoices-invoice-id-copy: "record<data: record<id: string>, success: bool>"
    get-one-invoice-emails: "record<data: record<api_response: string, body: string, carbon_copy: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_sent: bool, modified: string, recipients: string, reply_to: string, subject: string>, success: bool>"
    get-invoice-files: "record<data: table<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    create-invoice-file: "record<data: record<id: string>, success: bool>"
    delete-invoices-invoice-id-files-file-id: "record<data: list<record>, success: bool>"
    get-one-invoice-files: "record<data: record<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, success: bool>"
    post-invoices-invoice-id-link-project-pdf: "record<data: list<string>, success: bool>"
    post-invoices-invoice-id-unlink-project-pdf: "record<data: list<string>, success: bool>"
    get-mass-messages-users: "record<data: table<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-mass-messages-users-mass-messages-user-id: "record<data: record<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record<company_id: string, content: string, created: string, created_by_id: string, deleted: string, id: string, modified: string>, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, success: bool>"
    put-mass-messages-users-mass-messages-user-id: "record<data: list<record>, success: bool>"
    get-materials: "record<data: table<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-materials: "record<data: record<id: string>, success: bool>"
    delete-materials-material-id: "record<data: list<record>, success: bool>"
    get-materials-material-id: "record<data: record<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, success: bool>"
    put-materials-material-id: "record<data: list<record>, success: bool>"
    get-materials-material-id-rentals: "record<data: table<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-materials-material-id-rentals: "record<data: record<id: string>, success: bool>"
    post-materials-material-id-rentals-checkout: "record<data: record<id: string>, success: bool>"
    delete-materials-material-id-rentals-material-rental-id: "record<data: record, success: bool>"
    get-materials-material-id-rentals-material-rental-id: "record<data: record<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, success: bool>"
    put-materials-material-id-rentals-material-rental-id: "record<data: record, success: bool>"
    get-offer-statuses: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-offer-statuses: "record<data: list<string>, success: bool>"
    delete-offer-statuses-bulk-delete: "record<data: list<string>, success: bool>"
    delete-offer-statuses-offer-status-id: "record<data: list<string>, success: bool>"
    get-offer-statuses-offer-status-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, success: bool>"
    put-offer-statuses-offer-status-id: "record<data: list<string>, success: bool>"
    get-offers: "record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-offers: "record<data: record<id: string>, success: bool>"
    delete-offers-offer-id: "record<data: list<string>, success: bool>"
    get-offers-offer-id: "record<data: record<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool>"
    put-offers-offer-id: "record<data: list<string>, success: bool>"
    get-offers-offer-id-changelog: "record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool>"
    get-overview-rejection-reasons: "record<data: list<any>, success: bool>"
    get-payment-term-types: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-payment-term-types-payment-term-type-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>"
    get-payment-terms: "record<data: table<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-payment-terms-erp: "record<data: table<daysOfCredit: int, id: string, name: string, pretty_string: string, type: string>, success: bool>"
    get-payment-terms-payment-term-id: "record<data: record<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, success: bool>"
    get-ping: "record<status: string>"
    get-products: "record<data: table<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-products: "record<data: record<id: string>, success: bool>"
    bulk-delete-products: "record<data: list<string>, success: bool>"
    post-products-undelete-product-id: "record<data: list<string>, success: bool>"
    delete-products-product-id: "record<data: list<string>, success: bool>"
    get-products-product-id: "record<data: record<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, success: bool>"
    put-products-product-id: "record<data: list<record>, success: bool>"
    get-products-product-id-variants: "record<data: table<name: string, price: float, product_number: string, variant_id: string, variant_type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-products-product-id-variants: "record<data: list<string>, success: bool>"
    delete-products-product-id-variants-variant-type-variant-id: "record<data: list<string>, success: bool>"
    get-project-custom-field-attributes: "record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-project-custom-field-attributes-project-custom-field-attribute-id: "record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>"
    get-project-status-types: "record<data: table<_locale: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-project-statuses: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-project-statuses: "record<data: record<id: string>, success: bool>"
    post-project-statuses-add-default: "record<message: string, success: bool>"
    delete-project-statuses-bulk-delete: "record<data: list<string>, success: bool>"
    delete-project-statuses-project-status-id: "record<data: list<string>, success: bool>"
    get-project-statuses-project-status-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool>"
    put-project-statuses-project-status-id: "record<data: list<string>, success: bool>"
    get-projects: "record<data: table<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-projects: "record<data: record<id: string>, success: bool>"
    get-projects-has-projects-with-custom-statuses: "record<has_custom_statuses: bool, success: bool>"
    delete-projects-project-id: "record<data: list<string>, success: bool>"
    get-projects-project-id: "record<data: record<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, success: bool>"
    put-projects-project-id: "record<data: list<record>, success: bool>"
    get-projects-project-id-all-files: "record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-projects-project-id-files: "record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    delete-projects-project-id-files-file-id: "record<data: record, success: bool>"
    get-projects-project-id-files-file-id: "record<data: record, success: bool>"
    put-projects-project-id-files-file-id: "record<data: record, success: bool>"
    get-projects-project-id-project-files: "record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-projects-project-id-project-files: "record<data: record<id: string>, success: bool>"
    delete-projects-project-id-project-files-project-file-id: "record<data: record, success: bool>"
    get-projects-project-id-project-files-project-file-id: "record<data: record, success: bool>"
    put-projects-project-id-project-files-project-file-id: "record<data: record, success: bool>"
    post-projects-project-id-send-bulk-pdf: "record<data: list<string>, success: bool>"
    get-projects-project-id-users: "record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-projects-project-id-users: "record<data: record<id: string>, success: bool>"
    delete-projects-project-id-users-user-id: "record<data: list<record>, success: bool>"
    get-projects-project-id-users-user-id: "record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool>"
    get-roles: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-stock-locations: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-stock-locations: "record<data: record<id: string>, success: bool>"
    delete-stock-locations-location-id: "record<data: list<record>, success: bool>"
    get-stock-locations-location-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, success: bool>"
    put-stock-locations-location-id: "record<data: list<record>, success: bool>"
    get-time-entries: "record<data: table<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-time-entries: "record<data: record<id: string>, success: bool>"
    delete-time-entries-time-entry-id: "record<data: list<record>, success: bool>"
    get-time-entries-time-entry-id: "record<data: record<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, success: bool>"
    put-time-entries-time-entry-id: "record<data: list<record>, success: bool>"
    get-time-entry-intervals: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-time-entry-intervals-time-entry-interval-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool>"
    get-time-entry-rates: "record<data: table<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-time-entry-rates: "record<data: record<id: string>, success: bool>"
    delete-time-entry-rates-time-entry-rate-id: "record<data: list<record>, success: bool>"
    get-time-entry-rates-time-entry-rate-id: "record<data: record<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, success: bool>"
    put-time-entry-rates-time-entry-rate-id: "record<data: list<record>, success: bool>"
    get-time-entry-rule-groups: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, name: string, salary_period_days: float, salary_period_from: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-time-entry-types: "record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-time-entry-types: "record<data: record<id: string>, success: bool>"
    bulk-activate-time-entry-types: "record<data: list<string>, success: bool>"
    bulk-deactivate-time-entry-types: "record<data: list<string>, success: bool>"
    bulk-delete-time-entry-types: "record<data: list<string>, success: bool>"
    delete-time-entry-types-time-entry-type-id: "record<data: list<record>, success: bool>"
    get-time-entry-types-time-entry-type-id: "record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, success: bool>"
    put-time-entry-types-time-entry-type-id: "record<data: list<record>, success: bool>"
    get-time-entry-unit-types: "record<data: table<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-time-entry-unit-types-time-entry-unit-type-id: "record<data: record<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool>"
    get-time-entry-value-types: "record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-time-entry-value-types-time-entry-value-type-id: "record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, success: bool>"
    get-user-custom-field-attributes: "record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-user-custom-field-attributes-user-custom-field-attribute-id: "record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>"
    get-users: "record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-users: "record<data: record<id: string>, success: bool>"
    users-bulk-activate: "record<data: list<string>, success: bool>"
    users-bulk-deactivate: "record<data: list<string>, success: bool>"
    get-users-resend-welcome-sms: "record<data: record<message: string>, status: string>"
    delete-users-user-id: "record<data: list<record>, success: bool>"
    get-users-user-id: "record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool>"
    put-users-user-id: "record<data: list<record>, success: bool>"
    get-users-user-id-integration-settings: "record<data: table<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-users-user-id-integration-settings: "record<data: record<id: string>, success: bool>"
    delete-users-user-id-integration-settings-integration-settings-user-id: "record<data: list<string>, success: bool>"
    get-users-user-id-integration-settings-integration-settings-user-id: "record<data: record<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, success: bool>"
    put-users-user-id-integration-settings-integration-settings-user-id: "record<data: list<string>, success: bool>"
    post-users-user-id-upload-image: "record<data: record<id: string>, success: bool>"
    get-users-user-id-user-custom-field-value: "record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-users-user-id-user-custom-field-value-user-custom-field-value-id: "record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, success: bool>"
    put-users-user-id-user-custom-field-value-user-custom-field-value-id: "record<data: list<any>, success: bool>"
    get-vendor-product-price-files: "record<data: table<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-vendor-product-price-files: "record<data: record<id: string>, success: bool>"
    get-vendor-product-price-files-vendor-product-price-file-id: "record<data: record<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int, download_link: string>, success: bool>"
    get-vendor-products: "record<data: table<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    get-vendor-products-vendor-product-id: "record<data: record<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, success: bool>"
    get-vendors-list: "record<data: table<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    add-vendor: "record<data: record<id: string>, success: bool>"
    delete-vendors-vendor-id: "record<data: list<string>, success: bool>"
    get-vendor: "record<data: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool>"
    edit-vendor: "record<data: list<record>, success: bool>"
    post-wall-comments: "record<data: record<id: string>, success: bool>"
    get-wall-comments-wall-comment-id: "record<data: record<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, success: bool>"
    get-wall-posts: "record<data: table<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
    post-wall-posts: "record<data: record<id: string>, success: bool>"
    get-wall-posts-wall-post-id: "record<data: record<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, success: bool>"
    get-wall-posts-wall-post-id-wall-comments: "record<data: table<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-activities" "post-activities" "delete-activities-bulk-delete" "delete-activities-activity-id" "put-activities-activity-id" "get-cities" "get-cities-city-id" "get-clocking-records" "post-clocking-records" "post-clocking-records-checkout" "delete-clocking-records-clocking-record-id" "get-clocking-records-clocking-record-id" "put-clocking-records-clocking-record-id" "get-companies" "get-companies-subscription-self-service" "get-companies-company-id" "get-companies-company-id-companies-integration-feature-settings" "post-companies-company-id-companies-integration-feature-settings" "get-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id" "put-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id" "get-companies-company-id-form-templates" "delete-companies-company-id-form-templates-form-template-id" "get-companies-company-id-form-templates-form-template-id" "get-companies-company-id-integration-feature-settings" "get-companies-company-id-integration-feature-settings-integration-feature-setting-id" "get-companies-company-id-integration-settings" "post-companies-company-id-integration-settings" "delete-companies-company-id-integration-settings-companies-integration-setting-id" "get-companies-company-id-integration-settings-companies-integration-setting-id" "put-companies-company-id-integration-settings-companies-integration-setting-id" "delete-companies-company-id-price-margins-price-margins-id" "get-companies-company-id-price-margins-price-margins-id" "post-companies-company-id-price-margins-price-margins-id" "get-compaies-vendors-list" "add-companies-vendor" "bulk-companies-vendors" "delete-companies-vendors-companies-vendor-id" "get-companies-vendor" "edit-companies-vendor" "get-companies-vendors-expense-statistics" "get-compay-settings-list" "get-contact-custom-field-attributes" "get-contact-custom-field-attributes-contact-custom-field-attribute-id" "get-contact-types" "get-contact-types-contact-type-id" "get-contacts" "post-contacts" "bulk-delete-contacts" "delete-contacts-contact-id" "get-contacts-contact-id" "put-contacts-contact-id" "get-contacts-contact-id-contact-custom-field-values" "get-contact-persons-list" "add-contact-person" "delete-contacts-contact-id-contact-persons-contact-person-id" "get-contact-person" "edit-contact-person" "get-countries" "get-countries-country-id" "get-currencies" "get-currencies-currency-id" "get-driving-types" "post-driving-types" "bulk-delete-driving-types" "delete-driving-types-driving-type-id" "get-driving-types-driving-type-id" "put-driving-types-driving-type-id" "get-employee-hours" "get-events" "post-events" "get-events-is-user-free" "delete-events-event-id" "get-events-event-id" "put-events-event-id" "get-expense-files" "post-expense-files" "delete-expense-files-expense-file-id" "get-expense-files-expense-file-id" "put-expense-files-expense-file-id" "get-expense-lines" "post-expense-lines" "delete-expense-lines-expense-line-id" "get-expense-lines-expense-line-id" "put-expense-lines-expense-line-id" "get-expenses" "post-expenses" "bulk-delete-expenses" "get-expenses-highest-amount" "send-emails-expenses" "delete-expenses-expense-id" "get-expenses-expense-id" "put-expenses-expense-id" "get-expenses-expense-id-original-files" "get-expenses-expense-id-original-files-file-id" "get-financial-statistics" "get-expenses-sales-price" "get-invoiced-amount" "get-margin" "get-material-rentals-cost-price" "get-financial-statistics-overview" "get-products-cost-price" "get-financial-statistics-working-hours" "get-form-field-types" "get-form-field-types-form-field-type-id" "post-form-fields" "get-form-fields-form-field-id" "get-form-templates" "get-form-templates-form-template-id" "get-forms" "post-forms" "get-forms-undelete-form-id" "get-forms-view-time-form-pdf-form-id" "delete-forms-form-id" "get-forms-form-id" "put-forms-form-id" "get-integrations-list" "post-integrations-billys-authenticate" "get-integrations-contacts-sync" "get-integrations-products-sync" "get-integrations-view" "get-invoice-line-text-template" "post-invoice-line-text-template" "delete-invoice-line-text-template-invoice-line-text-template-id" "get-invoice-line-text-template-invoice-line-text-template-id" "post-invoice-line-text-template-invoice-line-text-template-id" "post-invoice-line-texts" "post-invoice-line-texts-invoice-line-text-id" "get-invoice-lines" "post-invoice-lines" "delete-invoice-lines-invoice-line-id" "get-invoice-lines-invoice-line-id" "put-invoice-lines-invoice-line-id" "get-invoices" "post-invoices" "bulk-delete-invoices" "get-invoices-vat-options" "delete-invoices-invoice-id" "get-invoices-invoice-id" "put-invoices-invoice-id" "post-invoices-invoice-id-copy" "get-one-invoice-emails" "get-invoice-files" "create-invoice-file" "delete-invoices-invoice-id-files-file-id" "get-one-invoice-files" "post-invoices-invoice-id-link-project-pdf" "post-invoices-invoice-id-unlink-project-pdf" "get-mass-messages-users" "get-mass-messages-users-mass-messages-user-id" "put-mass-messages-users-mass-messages-user-id" "get-materials" "post-materials" "delete-materials-material-id" "get-materials-material-id" "put-materials-material-id" "get-materials-material-id-rentals" "post-materials-material-id-rentals" "post-materials-material-id-rentals-checkout" "delete-materials-material-id-rentals-material-rental-id" "get-materials-material-id-rentals-material-rental-id" "put-materials-material-id-rentals-material-rental-id" "get-offer-statuses" "post-offer-statuses" "delete-offer-statuses-bulk-delete" "delete-offer-statuses-offer-status-id" "get-offer-statuses-offer-status-id" "put-offer-statuses-offer-status-id" "get-offers" "post-offers" "delete-offers-offer-id" "get-offers-offer-id" "put-offers-offer-id" "get-offers-offer-id-changelog" "get-overview-rejection-reasons" "get-payment-term-types" "get-payment-term-types-payment-term-type-id" "get-payment-terms" "get-payment-terms-erp" "get-payment-terms-payment-term-id" "get-ping" "get-products" "post-products" "bulk-delete-products" "post-products-undelete-product-id" "delete-products-product-id" "get-products-product-id" "put-products-product-id" "upload-or-delete-product-image" "get-products-product-id-variants" "post-products-product-id-variants" "delete-products-product-id-variants-variant-type-variant-id" "get-project-custom-field-attributes" "get-project-custom-field-attributes-project-custom-field-attribute-id" "get-project-status-types" "get-project-statuses" "post-project-statuses" "post-project-statuses-add-default" "delete-project-statuses-bulk-delete" "delete-project-statuses-project-status-id" "get-project-statuses-project-status-id" "put-project-statuses-project-status-id" "get-projects" "post-projects" "get-projects-has-projects-with-custom-statuses" "delete-projects-project-id" "get-projects-project-id" "put-projects-project-id" "get-projects-project-id-all-files" "get-projects-project-id-files" "delete-projects-project-id-files-file-id" "get-projects-project-id-files-file-id" "put-projects-project-id-files-file-id" "get-projects-project-id-project-files" "post-projects-project-id-project-files" "delete-projects-project-id-project-files-project-file-id" "get-projects-project-id-project-files-project-file-id" "put-projects-project-id-project-files-project-file-id" "post-projects-project-id-send-bulk-pdf" "get-projects-project-id-users" "post-projects-project-id-users" "delete-projects-project-id-users-user-id" "get-projects-project-id-users-user-id" "get-reports" "get-roles" "get-stock-locations" "post-stock-locations" "delete-stock-locations-location-id" "get-stock-locations-location-id" "put-stock-locations-location-id" "get-time-entries" "post-time-entries" "delete-time-entries-time-entry-id" "get-time-entries-time-entry-id" "put-time-entries-time-entry-id" "get-time-entry-intervals" "get-time-entry-intervals-time-entry-interval-id" "get-time-entry-rates" "post-time-entry-rates" "delete-time-entry-rates-time-entry-rate-id" "get-time-entry-rates-time-entry-rate-id" "put-time-entry-rates-time-entry-rate-id" "get-time-entry-rule-groups" "get-time-entry-types" "post-time-entry-types" "bulk-activate-time-entry-types" "bulk-deactivate-time-entry-types" "bulk-delete-time-entry-types" "delete-time-entry-types-time-entry-type-id" "get-time-entry-types-time-entry-type-id" "put-time-entry-types-time-entry-type-id" "get-time-entry-unit-types" "get-time-entry-unit-types-time-entry-unit-type-id" "get-time-entry-value-types" "get-time-entry-value-types-time-entry-value-type-id" "get-user-custom-field-attributes" "get-user-custom-field-attributes-user-custom-field-attribute-id" "get-users" "post-users" "users-bulk-activate" "users-bulk-deactivate" "get-users-resend-welcome-sms" "delete-users-user-id" "get-users-user-id" "put-users-user-id" "get-users-user-id-integration-settings" "post-users-user-id-integration-settings" "delete-users-user-id-integration-settings-integration-settings-user-id" "get-users-user-id-integration-settings-integration-settings-user-id" "put-users-user-id-integration-settings-integration-settings-user-id" "post-users-user-id-upload-image" "get-users-user-id-user-custom-field-value" "get-users-user-id-user-custom-field-value-user-custom-field-value-id" "put-users-user-id-user-custom-field-value-user-custom-field-value-id" "get-vendor-product-price-files" "post-vendor-product-price-files" "get-vendor-product-price-files-vendor-product-price-file-id" "get-vendor-products" "get-vendor-products-vendor-product-id" "get-vendors-list" "add-vendor" "delete-vendors-vendor-id" "get-vendor" "edit-vendor" "get-wages-download-salary-file" "post-wall-comments" "get-wall-comments-wall-comment-id" "get-wall-posts" "post-wall-posts" "get-wall-posts-wall-post-id" "get-wall-posts-wall-post-id-wall-comments" "commands"] | sort) } | get name | first)
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

# Get a list of activities
#
# GET /activities
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, hex_code: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-activities" [
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
    path: "/activities"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an activity
#
# POST /activities
# Returns: record<data: list<string>, success: bool>
export def "post-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hex-code: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/activities"
    body: {content_type: "application/json", kind: json, fields: [{name: hex_code, var: hex_code}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    hex_code: $hex_code, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete activities
#
# DELETE /activities/bulkDelete
# Returns: record<data: list<string>, success: bool>
export def "delete-activities-bulk-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/activities/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an activity
#
# DELETE /activities/{activity_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-activities-activity-id" [
  activity_id: string
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
    path: "/activities/{activity_id}"
    path_params: [{name: activity_id, var: activity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an activity
#
# PUT /activities/{activity_id}
# Returns: record<data: list<string>, success: bool>
export def "put-activities-activity-id" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hex-code: string
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/activities/{activity_id}"
    path_params: [{name: activity_id, var: activity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hex_code, var: hex_code}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    activity_id: $activity_id, hex_code: $hex_code, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of cities supported in Apacta
#
# GET /cities
# Returns: record<data: table<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-cities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zip-code: string # Used to search for a city with specific zip code
  --name: string # Used to search for a city by name
  --include-all: oneof<nothing, bool> # Used to search for a city without filtering by country
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cities"
    query: [{name: zip_code, var: zip_code}, {name: name, var: name}, {name: include_all, var: include_all}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    zip_code: $zip_code, name: $name, include_all: $include_all
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about one city
#
# GET /cities/{city_id}
# Returns: record<data: record<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, success: bool>
export def "get-cities-city-id" [
  city_id: string
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
    path: "/cities/{city_id}"
    path_params: [{name: city_id, var: city_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    city_id: $city_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of clocking records
#
# GET /clocking_records
# Returns: record<data: table<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-clocking-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Used to search for active clocking records
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/clocking_records"
    query: [{name: active, var: active}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    active: $active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clocking record for authenticated user
#
# POST /clocking_records
# Returns: record<data: record<id: string>, success: bool>
export def "post-clocking-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkin-latitude: string
  --checkin-longitude: string
  --checkout-latitude: string
  --checkout-longitude: string
  --project-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clocking_records"
    body: {content_type: "application/json", kind: json, fields: [{name: checkin_latitude, var: checkin_latitude}, {name: checkin_longitude, var: checkin_longitude}, {name: checkout_latitude, var: checkout_latitude}, {name: checkout_longitude, var: checkout_longitude}, {name: project_id, var: project_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    checkin_latitude: $checkin_latitude, checkin_longitude: $checkin_longitude, checkout_latitude: $checkout_latitude, checkout_longitude: $checkout_longitude, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checkout active clocking record for authenticated user
#
# POST /clocking_records/checkout
# Returns: record<success: bool>
export def "post-clocking-records-checkout" [
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
    path: "/clocking_records/checkout"
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a clocking record
#
# DELETE /clocking_records/{clocking_record_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-clocking-records-clocking-record-id" [
  clocking_record_id: string
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
    path: "/clocking_records/{clocking_record_id}"
    path_params: [{name: clocking_record_id, var: clocking_record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    clocking_record_id: $clocking_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 clocking_record
#
# GET /clocking_records/{clocking_record_id}
# Returns: record<data: record<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, success: bool>
export def "get-clocking-records-clocking-record-id" [
  clocking_record_id: string
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
    path: "/clocking_records/{clocking_record_id}"
    path_params: [{name: clocking_record_id, var: clocking_record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    clocking_record_id: $clocking_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a clocking record
#
# PUT /clocking_records/{clocking_record_id}
# Returns: record<data: list<record>, success: bool>
export def "put-clocking-records-clocking-record-id" [
  clocking_record_id: string
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
    path: "/clocking_records/{clocking_record_id}"
    path_params: [{name: clocking_record_id, var: clocking_record_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    clocking_record_id: $clocking_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of companies
#
# GET /companies
# Returns: record<data: table<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies" [
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
    path: "/companies"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# URL for subscription selfservice
#
# GET /companies/subscription_self_service
# Returns: record<data: record<subscription_self_service_url: string>, success: bool>
export def "get-companies-subscription-self-service" [
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
    path: "/companies/subscription_self_service"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 company
#
# GET /companies/{company_id}
# Returns: record<data: record<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, success: bool>
export def "get-companies-company-id" [
  company_id: string
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
    path: "/companies/{company_id}"
    path_params: [{name: company_id, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a company integration feature settings
#
# GET /companies/{company_id}/companies_integration_feature_settings
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>
export def "get-companies-company-id-companies-integration-feature-settings" [
  company_id: string
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
    path: "/companies/{company_id}/companies_integration_feature_settings"
    path_params: [{name: company_id, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a company integration feature setting
#
# POST /companies/{company_id}/companies_integration_feature_settings
# Returns: record<data: record<id: string>, success: bool>
export def "post-companies-company-id-companies-integration-feature-settings" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-feature-setting-id: string # format: uuid
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{company_id}/companies_integration_feature_settings"
    path_params: [{name: company_id, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: integration_feature_setting_id, var: integration_feature_setting_id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    company_id: $company_id, integration_feature_setting_id: $integration_feature_setting_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a company integration feature setting
#
# GET /companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>
export def "get-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id" [
  company_id: string
  c_integration_feature_setting_id: string
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
    path: "/companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: c_integration_feature_setting_id, var: c_integration_feature_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, c_integration_feature_setting_id: $c_integration_feature_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a company integration feature setting
#
# PUT /companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool>
export def "put-companies-company-id-companies-integration-feature-settings-c-integration-feature-setting-id" [
  company_id: string
  c_integration_feature_setting_id: string
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
    path: "/companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: c_integration_feature_setting_id, var: c_integration_feature_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, c_integration_feature_setting_id: $c_integration_feature_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of company form templates
#
# GET /companies/{company_id}/form_templates/
# Returns: record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies-company-id-form-templates" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-template-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{company_id}/form_templates/"
    path_params: [{name: company_id, var: company_id}]
    query: [{name: form_template_id, var: form_template_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, form_template_id: $form_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a form template company
#
# DELETE /companies/{company_id}/form_templates/{form_template_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-companies-company-id-form-templates-form-template-id" [
  company_id: string
  form_template_id: string
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
    path: "/companies/{company_id}/form_templates/{form_template_id}"
    path_params: [{name: company_id, var: company_id}, {name: form_template_id, var: form_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, form_template_id: $form_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a company form template
#
# GET /companies/{company_id}/form_templates/{form_template_id}
# Returns: record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies-company-id-form-templates-form-template-id" [
  company_id: string
  form_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{company_id}/form_templates/{form_template_id}"
    path_params: [{name: company_id, var: company_id}, {name: form_template_id, var: form_template_id}]
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, form_template_id: $form_template_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of integration feature settings
#
# GET /companies/{company_id}/integration_feature_settings
# Returns: record<data: table<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies-company-id-integration-feature-settings" [
  company_id: string
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
    path: "/companies/{company_id}/integration_feature_settings"
    path_params: [{name: company_id, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show details of 1 integration feature setting
#
# GET /companies/{company_id}/integration_feature_settings/{integration_feature_setting_id}
# Returns: record<data: record<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, success: bool>
export def "get-companies-company-id-integration-feature-settings-integration-feature-setting-id" [
  company_id: string
  integration_feature_setting_id: string
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
    path: "/companies/{company_id}/integration_feature_settings/{integration_feature_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: integration_feature_setting_id, var: integration_feature_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, integration_feature_setting_id: $integration_feature_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of company integration settings
#
# GET /companies/{company_id}/integration_settings
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies-company-id-integration-settings" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string # The identifier of an ERP integration
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/companies/{company_id}/integration_settings"
    path_params: [{name: company_id, var: company_id}]
    query: [{name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a company integration setting
#
# POST /companies/{company_id}/integration_settings
# Returns: record<data: record<id: string>, success: bool>
export def "post-companies-company-id-integration-settings" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-setting-id: string # format: uuid
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{company_id}/integration_settings"
    path_params: [{name: company_id, var: company_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: integration_setting_id, var: integration_setting_id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    company_id: $company_id, integration_setting_id: $integration_setting_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a company integration setting
#
# DELETE /companies/{company_id}/integration_settings/{companies_integration_setting_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-companies-company-id-integration-settings-companies-integration-setting-id" [
  company_id: string
  companies_integration_setting_id: string
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
    path: "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: companies_integration_setting_id, var: companies_integration_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, companies_integration_setting_id: $companies_integration_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a company integration setting
#
# GET /companies/{company_id}/integration_settings/{companies_integration_setting_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, success: bool>
export def "get-companies-company-id-integration-settings-companies-integration-setting-id" [
  company_id: string
  companies_integration_setting_id: string
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
    path: "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: companies_integration_setting_id, var: companies_integration_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, companies_integration_setting_id: $companies_integration_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a company integration setting
#
# PUT /companies/{company_id}/integration_settings/{companies_integration_setting_id}
# Returns: record<data: list<string>, success: bool>
export def "put-companies-company-id-integration-settings-companies-integration-setting-id" [
  company_id: string
  companies_integration_setting_id: string
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
    path: "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"
    path_params: [{name: company_id, var: company_id}, {name: companies_integration_setting_id, var: companies_integration_setting_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, companies_integration_setting_id: $companies_integration_setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a company price margin
#
# DELETE /companies/{company_id}/price_margins/{price_margins_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-companies-company-id-price-margins-price-margins-id" [
  company_id: string
  price_margins_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --price-margin-id: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/companies/{company_id}/price_margins/{price_margins_id}"
    path_params: [{name: company_id, var: company_id}, {name: price_margins_id, var: price_margins_id}]
    query: [{name: price_margin_id, var: price_margin_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, price_margins_id: $price_margins_id, price_margin_id: $price_margin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of company price margins
#
# GET /companies/{company_id}/price_margins/{price_margins_id}
# Returns: record<data: table<amount_from: float, amount_to: float, company_id: string, created: string, deleted: string, id: string, modified: string, percentage_ratio: float, ratio: float, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-companies-company-id-price-margins-price-margins-id" [
  company_id: string
  price_margins_id: string
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
    path: "/companies/{company_id}/price_margins/{price_margins_id}"
    path_params: [{name: company_id, var: company_id}, {name: price_margins_id, var: price_margins_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, price_margins_id: $price_margins_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a company price margin
#
# POST /companies/{company_id}/price_margins/{price_margins_id}
# Returns: record<data: record<id: string>, success: bool>
export def "post-companies-company-id-price-margins-price-margins-id" [
  company_id: string
  price_margins_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # format: uuid
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies/{company_id}/price_margins/{price_margins_id}"
    path_params: [{name: company_id, var: company_id}, {name: price_margins_id, var: price_margins_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    company_id: $company_id, price_margins_id: $price_margins_id, id: $id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of companies vendors
#
# GET /companies_vendors
# Returns: record<data: table<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
# operationId: getCompaiesVendorsList
export def "get-compaies-vendors-list" [
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
    path: "/companies_vendors"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new companies vendor
#
# POST /companies_vendors
# Returns: record<data: record<id: string>, success: bool>
# operationId: addCompaniesVendor
export def "add-companies-vendor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --delivery-price: float # format: float
  --free-delivery-price: float # format: float
  --is-active: oneof<nothing, bool>
  --password: string
  --receive-automatic-price-files: oneof<nothing, bool>
  --receive-invoice-mails: oneof<nothing, bool>
  --reviewed: oneof<nothing, bool>
  --use-price-files: oneof<nothing, bool>
  --username: string
  --vendor-account-reference: string
  --vendor-department-id: string # format: uuid
  --vendor-email: string
  --vendor-id: string # format: uuid
  --vendor-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/companies_vendors"
    body: {content_type: "application/json", kind: json, fields: [{name: company_id, var: company_id}, {name: delivery_price, var: delivery_price}, {name: free_delivery_price, var: free_delivery_price}, {name: is_active, var: is_active}, {name: password, var: password}, {name: receive_automatic_price_files, var: receive_automatic_price_files}, {name: receive_invoice_mails, var: receive_invoice_mails}, {name: reviewed, var: reviewed}, {name: use_price_files, var: use_price_files}, {name: username, var: username}, {name: vendor_account_reference, var: vendor_account_reference}, {name: vendor_department_id, var: vendor_department_id}, {name: vendor_email, var: vendor_email}, {name: vendor_id, var: vendor_id}, {name: vendor_name, var: vendor_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    company_id: $company_id, delivery_price: $delivery_price, free_delivery_price: $free_delivery_price, is_active: $is_active, password: $password, receive_automatic_price_files: $receive_automatic_price_files, receive_invoice_mails: $receive_invoice_mails, reviewed: $reviewed, use_price_files: $use_price_files, username: $username, vendor_account_reference: $vendor_account_reference, vendor_department_id: $vendor_department_id, vendor_email: $vendor_email, vendor_id: $vendor_id, vendor_name: $vendor_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete companies vendors
#
# DELETE /companies_vendors/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkCompaniesVendors
export def "bulk-companies-vendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/companies_vendors/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a companies vendor
#
# DELETE /companies_vendors/{companies_vendor_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-companies-vendors-companies-vendor-id" [
  companies_vendor_id: string
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
    path: "/companies_vendors/{companies_vendor_id}"
    path_params: [{name: companies_vendor_id, var: companies_vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    companies_vendor_id: $companies_vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a companies vendor
#
# GET /companies_vendors/{companies_vendor_id}
# Returns: record<data: record<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, success: bool>
# operationId: getCompaniesVendor
export def "get-companies-vendor" [
  companies_vendor_id: string
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
    path: "/companies_vendors/{companies_vendor_id}"
    path_params: [{name: companies_vendor_id, var: companies_vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    companies_vendor_id: $companies_vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a companies vendor
#
# PUT /companies_vendors/{companies_vendor_id}
# Returns: record<data: list<record>, success: bool>
# operationId: editCompaniesVendor
export def "edit-companies-vendor" [
  companies_vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --delivery-price: float # format: float
  --free-delivery-price: float # format: float
  --is-active: oneof<nothing, bool>
  --password: string
  --receive-automatic-price-files: oneof<nothing, bool>
  --receive-invoice-mails: oneof<nothing, bool>
  --reviewed: oneof<nothing, bool>
  --use-price-files: oneof<nothing, bool>
  --username: string
  --vendor-account-reference: string
  --vendor-department-id: string # format: uuid
  --vendor-email: string
  --vendor-id: string # format: uuid
  --vendor-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/companies_vendors/{companies_vendor_id}"
    path_params: [{name: companies_vendor_id, var: companies_vendor_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: company_id, var: company_id}, {name: delivery_price, var: delivery_price}, {name: free_delivery_price, var: free_delivery_price}, {name: is_active, var: is_active}, {name: password, var: password}, {name: receive_automatic_price_files, var: receive_automatic_price_files}, {name: receive_invoice_mails, var: receive_invoice_mails}, {name: reviewed, var: reviewed}, {name: use_price_files, var: use_price_files}, {name: username, var: username}, {name: vendor_account_reference, var: vendor_account_reference}, {name: vendor_department_id, var: vendor_department_id}, {name: vendor_email, var: vendor_email}, {name: vendor_id, var: vendor_id}, {name: vendor_name, var: vendor_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    companies_vendor_id: $companies_vendor_id, company_id: $company_id, delivery_price: $delivery_price, free_delivery_price: $free_delivery_price, is_active: $is_active, password: $password, receive_automatic_price_files: $receive_automatic_price_files, receive_invoice_mails: $receive_invoice_mails, reviewed: $reviewed, use_price_files: $use_price_files, username: $username, vendor_account_reference: $vendor_account_reference, vendor_department_id: $vendor_department_id, vendor_email: $vendor_email, vendor_id: $vendor_id, vendor_name: $vendor_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get companies vendor expense statistics
#
# GET /companies_vendors/{companies_vendor_id}/expense_statistics
# Returns: record<data: table<last_month: list, thirty_days: list, vendor_id: string>>
# operationId: getCompaniesVendorsExpenseStatistics
export def "get-companies-vendors-expense-statistics" [
  companies_vendor_id: string
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
    path: "/companies_vendors/{companies_vendor_id}/expense_statistics"
    path_params: [{name: companies_vendor_id, var: companies_vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    companies_vendor_id: $companies_vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of company settings
#
# GET /company_settings
# Returns: record<data: record<company_settings_category_id: string, created: string, created_by_id: string, default_value: string, deleted: string, description: string, feature_id: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, options: string, placement: int, type: string>, success: bool>
# operationId: getCompaySettingsList
export def "get-compay-settings-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter by name
  --description: string # Filter by description
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/company_settings"
    query: [{name: name, var: name}, {name: description, var: description}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of contact custom field attributes
#
# GET /contact_custom_field_attributes
# Returns: record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-contact-custom-field-attributes" [
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
    path: "/contact_custom_field_attributes"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 contact custom field attribute
#
# GET /contact_custom_field_attributes/{contact_custom_field_attribute_id}
# Returns: record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>
export def "get-contact-custom-field-attributes-contact-custom-field-attribute-id" [
  contact_custom_field_attribute_id: string
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
    path: "/contact_custom_field_attributes/{contact_custom_field_attribute_id}"
    path_params: [{name: contact_custom_field_attribute_id, var: contact_custom_field_attribute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_custom_field_attribute_id: $contact_custom_field_attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of contact types supported in Apacta
#
# GET /contact_types
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-contact-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string # Search for specific identifier value
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contact_types"
    query: [{name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about one contact type
#
# GET /contact_types/{contact_type_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>
export def "get-contact-types-contact-type-id" [
  contact_type_id: string
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
    path: "/contact_types/{contact_type_id}"
    path_params: [{name: contact_type_id, var: contact_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_type_id: $contact_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of contacts
#
# GET /contacts
# Returns: record<data: table<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to search for a contact with a specific name
  --cvr: string # Search for values in CVR field
  --ean: string # Search for values in EAN field
  --erp-id: string # Search for values in ERP id field
  --contact-type: string # Used to show only contacts with with one specific `ContactType` (format: uuid)
  --city: string # Used to show only contacts with with one specific `City`
  --modified-gte: string # format: datetime
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts"
    query: [{name: name, var: name}, {name: cvr, var: cvr}, {name: ean, var: ean}, {name: erp_id, var: erp_id}, {name: contact_type, var: contact_type}, {name: city, var: city}, {name: modified_gte, var: modified_gte}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, cvr: $cvr, ean: $ean, erp_id: $erp_id, contact_type: $contact_type, city: $city, modified_gte: $modified_gte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new contact
#
# POST /contacts
# Returns: record<data: record<id: string>, success: bool>
export def "post-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Street address
  --city-id: string # format: uuid
  --contact-types: record # shape: {_ids?: list<string>}
  --cvr: string
  --description: string
  --email: string
  --erp-id: string # If company has integration to an ERP system, and the contacts are synchronized, this will be the ERP-systems ID of this contact
  --name: string
  --phone: string # Format like eg. `28680133` or `046158971404`
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city_id, var: city_id}, {name: contact_types, var: contact_types}, {name: cvr, var: cvr}, {name: description, var: description}, {name: email, var: email}, {name: erp_id, var: erp_id}, {name: name, var: name}, {name: phone, var: phone}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    address: $address, city_id: $city_id, contact_types: $contact_types, cvr: $cvr, description: $description, email: $email, erp_id: $erp_id, name: $name, phone: $phone, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete contacts
#
# DELETE /contacts/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteContacts
export def "bulk-delete-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/contacts/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact
#
# DELETE /contacts/{contact_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-contacts-contact-id" [
  contact_id: string
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
    path: "/contacts/{contact_id}"
    path_params: [{name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 contact
#
# GET /contacts/{contact_id}
# Returns: record<data: record<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, success: bool>
export def "get-contacts-contact-id" [
  contact_id: string
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
    path: "/contacts/{contact_id}"
    path_params: [{name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a contact
#
# PUT /contacts/{contact_id}
# Returns: record<data: list<record>, success: bool>
export def "put-contacts-contact-id" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Street address
  --city-id: string # format: uuid
  --contact-types: record # shape: {_ids?: list<string>}
  --cvr: string
  --description: string
  --email: string
  --erp-id: string # If company has integration to an ERP system, and the contacts are synchronized, this will be the ERP-systems ID of this contact
  --name: string
  --phone: string # Format like eg. `28680133` or `046158971404`
  --website: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contacts/{contact_id}"
    path_params: [{name: contact_id, var: contact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city_id, var: city_id}, {name: contact_types, var: contact_types}, {name: cvr, var: cvr}, {name: description, var: description}, {name: email, var: email}, {name: erp_id, var: erp_id}, {name: name, var: name}, {name: phone, var: phone}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, address: $address, city_id: $city_id, contact_types: $contact_types, cvr: $cvr, description: $description, email: $email, erp_id: $erp_id, name: $name, phone: $phone, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of contact custom field values
#
# GET /contacts/{contact_id}/contact_custom_field_values
# Returns: record<data: table<contact_custom_field_attribute_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-contacts-contact-id-contact-custom-field-values" [
  contact_id: string
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
    path: "/contacts/{contact_id}/contact_custom_field_values"
    path_params: [{name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of contact people
#
# GET /contacts/{contact_id}/contact_persons
# Returns: record<data: table<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
# operationId: getContactPersonsList
export def "get-contact-persons-list" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
  --created-gte: string # format: date
  --created-lte: string # format: date
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts/{contact_id}/contact_persons"
    path_params: [{name: contact_id, var: contact_id}]
    query: [{name: q, var: q}, {name: created_gte, var: created_gte}, {name: created_lte, var: created_lte}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, q: $q, created_gte: $created_gte, created_lte: $created_lte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new contact person to a contact
#
# POST /contacts/{contact_id}/contact_persons
# Returns: record<data: record<id: string>, success: bool>
# operationId: addContactPerson
export def "add-contact-person" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string
  --phone: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts/{contact_id}/contact_persons"
    path_params: [{name: contact_id, var: contact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: phone, var: phone}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    contact_id: $contact_id, email: $email, name: $name, phone: $phone, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact person
#
# DELETE /contacts/{contact_id}/contact_persons/{contact_person_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-contacts-contact-id-contact-persons-contact-person-id" [
  contact_id: string
  contact_person_id: string
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
    path: "/contacts/{contact_id}/contact_persons/{contact_person_id}"
    path_params: [{name: contact_id, var: contact_id}, {name: contact_person_id, var: contact_person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, contact_person_id: $contact_person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a contact person
#
# GET /contacts/{contact_id}/contact_persons/{contact_person_id}
# Returns: record<data: record<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, success: bool>
# operationId: getContactPerson
export def "get-contact-person" [
  contact_id: string
  contact_person_id: string
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
    path: "/contacts/{contact_id}/contact_persons/{contact_person_id}"
    path_params: [{name: contact_id, var: contact_id}, {name: contact_person_id, var: contact_person_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, contact_person_id: $contact_person_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a contact person
#
# PUT /contacts/{contact_id}/contact_persons/{contact_person_id}
# Returns: record<data: list<record>, success: bool>
# operationId: editContactPerson
export def "edit-contact-person" [
  contact_id: string
  contact_person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string
  --phone: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contacts/{contact_id}/contact_persons/{contact_person_id}"
    path_params: [{name: contact_id, var: contact_id}, {name: contact_person_id, var: contact_person_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: phone, var: phone}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, contact_person_id: $contact_person_id, email: $email, name: $name, phone: $phone, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of countries supported in Apacta
#
# GET /countries
# Returns: record<data: table<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-countries" [
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
    path: "/countries"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about one country
#
# GET /countries/{country_id}
# Returns: record<data: record<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, success: bool>
export def "get-countries-country-id" [
  country_id: string
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
    path: "/countries/{country_id}"
    path_params: [{name: country_id, var: country_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    country_id: $country_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of currencies supported in Apacta
#
# GET /currencies
# Returns: record<data: table<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-currencies" [
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
    path: "/currencies"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about one currency
#
# GET /currencies/{currency_id}
# Returns: record<data: record<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, success: bool>
export def "get-currencies-currency-id" [
  currency_id: string
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
    path: "/currencies/{currency_id}"
    path_params: [{name: currency_id, var: currency_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    currency_id: $currency_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the driving types of the company
#
# GET /driving_types
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
# operationId: get-driving_types
export def "get-driving-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
  --sort: string
  --direction: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/driving_types"
    query: [{name: q, var: q}, {name: sort, var: sort}, {name: direction, var: direction}]
    accept: ["application/json"]
    ok: [200]
    auth: query-api_token
  } {
    q: $q, sort: $sort, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create driving type
#
# POST /driving_types
# Returns: record<data: record<id: string>, success: bool>
# operationId: post-driving_types
export def "post-driving-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  company_id: string # format: uuid
  employee_price: float # format: float
  --erp-id: string
  invoice_price: float # format: float
  name: string
  --salary-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/driving_types"
    body: {content_type: "application/json", kind: json, fields: [{name: company_id, var: company_id}, {name: employee_price, var: employee_price}, {name: erp_id, var: erp_id}, {name: invoice_price, var: invoice_price}, {name: name, var: name}, {name: salary_id, var: salary_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, employee_price: $employee_price, erp_id: $erp_id, invoice_price: $invoice_price, name: $name, salary_id: $salary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete driving types
#
# DELETE /driving_types/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteDrivingTypes
export def "bulk-delete-driving-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/driving_types/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete driving type
#
# DELETE /driving_types/{driving_type_id}
# Returns: record<data: list<string>, success: bool>
# operationId: delete-driving_types-driving_type_id
export def "delete-driving-types-driving-type-id" [
  driving_type_id: string
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
    path: "/driving_types/{driving_type_id}"
    path_params: [{name: driving_type_id, var: driving_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    driving_type_id: $driving_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View driving type
#
# GET /driving_types/{driving_type_id}
# Returns: record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>
# operationId: get-driving_types-driving_type_id
export def "get-driving-types-driving-type-id" [
  driving_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-driving-type-id: string # required (spec name: driving_type_id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/driving_types/{driving_type_id}"
    path_params: [{name: driving_type_id, var: driving_type_id}]
    query: [{name: driving_type_id, var: qp_driving_type_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    driving_type_id: $driving_type_id, qp_driving_type_id: $qp_driving_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit driving type
#
# PUT /driving_types/{driving_type_id}
# Returns: record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>
# operationId: put-driving_types-driving_type_id
export def "put-driving-types-driving-type-id" [
  driving_type_id: string
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
    path: "/driving_types/{driving_type_id}"
    path_params: [{name: driving_type_id, var: driving_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    driving_type_id: $driving_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Used to retrieve details about the logged in user's hours
#
# GET /employee_hours
# Returns: record<data: table<form_date: string, form_id: string, project_name: string, total_hours: int, working_description: string, working_description_full: string>, success: bool>
export def "get-employee-hours" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date formatted as Y-m-d (2016-06-28) (required)
  --date-to: string # Date formatted as Y-m-d (2016-06-28) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/employee_hours"
    query: [{name: date_from, var: date_from, required: true}, {name: date_to, var: date_to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of events
#
# GET /events
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # format: uuid
  --project-id: string # format: uuid
  --start-gt: string # format: datetime
  --start-lt: string # format: datetime
  --start-eq: string # format: datetime
  --end-gt: string # format: datetime
  --end-lt: string # format: datetime
  --end-eq: string # format: datetime
  --tags: string # List events with given tag ids separated by comma. Example tags=0377d6ce-db5e-4b1e-ac3a-8ca39ea3142e,8cec327e-a559-4b40-9ed6-316b9de46743 (format: string)
  --without-users: oneof<nothing, bool> # List events without attached user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: user_id, var: user_id}, {name: project_id, var: project_id}, {name: "start[][gt]", var: start_gt}, {name: "start[][lt]", var: start_lt}, {name: "start[][eq]", var: start_eq}, {name: "end[][gt]", var: end_gt}, {name: "end[][lt]", var: end_lt}, {name: "end[][eq]", var: end_eq}, {name: tags, var: tags}, {name: without_users, var: without_users}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, project_id: $project_id, start_gt: $start_gt, start_lt: $start_lt, start_eq: $start_eq, end_gt: $end_gt, end_lt: $end_lt, end_eq: $end_eq, tags: $tags, without_users: $without_users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create event
#
# POST /events
# Returns: record<data: record<id: string>, success: bool>
export def "post-events" [
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
  --end: string # format: datetime
  --name: string
  --project-id: string # format: uuid
  --start: string # format: datetime
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/events"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: end, var: end}, {name: name, var: name}, {name: project_id, var: project_id}, {name: start, var: start}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    description: $description, end: $end, name: $name, project_id: $project_id, start: $start, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if user is available at given datetime range
#
# GET /events/is_user_free
# Returns: record<result: bool, success: bool>
export def "get-events-is-user-free" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # required, format: uuid
  --start: string # required, format: dateTime
  --end: string # required, format: dateTime
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/is_user_free"
    query: [{name: user_id, var: user_id, required: true}, {name: start, var: start, required: true}, {name: end, var: end, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete event
#
# DELETE /events/{event_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>
export def "delete-events-event-id" [
  event_id: string
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
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show event
#
# GET /events/{event_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>
export def "get-events-event-id" [
  event_id: string
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
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit event
#
# PUT /events/{event_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool>
export def "put-events-event-id" [
  event_id: string
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
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of expense files
#
# GET /expense_files
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, expense_id: string, file: string, file_extension: string, file_original_name: string, file_size: string, file_type: string, file_url: string, id: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-expense-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --expense-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/expense_files"
    query: [{name: created_by_id, var: created_by_id}, {name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    created_by_id: $created_by_id, expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add file to expense
#
# POST /expense_files
# Returns: record<data: record<id: string>, success: bool>
export def "post-expense-files" [
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
  file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/expense_files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    description: $description, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file
#
# DELETE /expense_files/{expense_file_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-expense-files-expense-file-id" [
  expense_file_id: string
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
    path: "/expense_files/{expense_file_id}"
    path_params: [{name: expense_file_id, var: expense_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_file_id: $expense_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show file
#
# GET /expense_files/{expense_file_id}
# Returns: record<data: list<string>, success: bool>
export def "get-expense-files-expense-file-id" [
  expense_file_id: string
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
    path: "/expense_files/{expense_file_id}"
    path_params: [{name: expense_file_id, var: expense_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_file_id: $expense_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit file
#
# PUT /expense_files/{expense_file_id}
# Returns: record<data: record, success: bool>
export def "put-expense-files-expense-file-id" [
  expense_file_id: string
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
    path: "/expense_files/{expense_file_id}"
    path_params: [{name: expense_file_id, var: expense_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_file_id: $expense_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of expense lines
#
# GET /expense_lines
# Returns: record<data: table<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-expense-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --currency-id: string # format: uuid
  --expense-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/expense_lines"
    query: [{name: created_by_id, var: created_by_id}, {name: currency_id, var: currency_id}, {name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    created_by_id: $created_by_id, currency_id: $currency_id, expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add line to expense
#
# POST /expense_lines
# Returns: record<data: record<id: string>, success: bool>
export def "post-expense-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buying-price: float # format: float
  --currency-id: string # format: uuid
  --expense-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/expense_lines"
    body: {content_type: "application/json", kind: json, fields: [{name: buying_price, var: buying_price}, {name: currency_id, var: currency_id}, {name: expense_id, var: expense_id}, {name: quantity, var: quantity}, {name: selling_price, var: selling_price}, {name: text, var: text}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    buying_price: $buying_price, currency_id: $currency_id, expense_id: $expense_id, quantity: $quantity, selling_price: $selling_price, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete expense line
#
# DELETE /expense_lines/{expense_line_id}
# Returns: record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>
export def "delete-expense-lines-expense-line-id" [
  expense_line_id: string
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
    path: "/expense_lines/{expense_line_id}"
    path_params: [{name: expense_line_id, var: expense_line_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_line_id: $expense_line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show expense line
#
# GET /expense_lines/{expense_line_id}
# Returns: record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>
export def "get-expense-lines-expense-line-id" [
  expense_line_id: string
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
    path: "/expense_lines/{expense_line_id}"
    path_params: [{name: expense_line_id, var: expense_line_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_line_id: $expense_line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit expense line
#
# PUT /expense_lines/{expense_line_id}
# Returns: record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool>
export def "put-expense-lines-expense-line-id" [
  expense_line_id: string
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
    path: "/expense_lines/{expense_line_id}"
    path_params: [{name: expense_line_id, var: expense_line_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_line_id: $expense_line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of expenses
#
# GET /expenses
# Returns: record<data: table<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-expenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --company-id: string # format: uuid
  --contact-id: string # format: uuid
  --project-id: string # format: uuid
  --due-date: string@due-date-completer # Filter by [valid=records in future including today], [exceeded=records in past] or [null=all records] (format: string)
  --gt-created: string # Created after date (format: date)
  --lt-created: string # Created before date (format: date)
  --status: string@status-completer # Filter by status identifier. [null=all records] (format: string)
  --is-imported: oneof<nothing, bool> # default: true
  --min-amount: float # Expenses `total_selling_price` > `min_amount` (format: float)
  --max-amount: float # Expenses `total_selling_price` < `max_amount` (format: float)
  --projects: string@projects-completer # You can select `all projects`, `no projects` or select `multiple projects`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/expenses"
    query: [{name: created_by_id, var: created_by_id}, {name: company_id, var: company_id}, {name: contact_id, var: contact_id}, {name: project_id, var: project_id}, {name: due_date, var: due_date}, {name: gt_created, var: gt_created}, {name: lt_created, var: lt_created}, {name: status, var: status}, {name: is_imported, var: is_imported}, {name: min_amount, var: min_amount}, {name: max_amount, var: max_amount}, {name: projects, var: projects}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    created_by_id: $created_by_id, company_id: $company_id, contact_id: $contact_id, project_id: $project_id, due_date: $due_date, gt_created: $gt_created, lt_created: $lt_created, status: $status, is_imported: $is_imported, min_amount: $min_amount, max_amount: $max_amount, projects: $projects
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add line to expense
#
# POST /expenses
# Returns: record<data: record<id: string>, success: bool>
export def "post-expenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --currency-id: string # format: uuid
  --delivery-date: string # format: date
  --description: string
  --project-id: string # format: uuid
  --reference: string
  --short-text: string
  --supplier-invoice-number: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/expenses"
    body: {content_type: "application/json", kind: json, fields: [{name: contact_id, var: contact_id}, {name: currency_id, var: currency_id}, {name: delivery_date, var: delivery_date}, {name: description, var: description}, {name: project_id, var: project_id}, {name: reference, var: reference}, {name: short_text, var: short_text}, {name: supplier_invoice_number, var: supplier_invoice_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    contact_id: $contact_id, currency_id: $currency_id, delivery_date: $delivery_date, description: $description, project_id: $project_id, reference: $reference, short_text: $short_text, supplier_invoice_number: $supplier_invoice_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete expenses
#
# DELETE /expenses/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteExpenses
export def "bulk-delete-expenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/expenses/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show highest Expense amount(`total_selling_price`)
#
# GET /expenses/highest_amount
# Returns: record<data: table<highest_amount: float>, success: bool>
export def "get-expenses-highest-amount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-created: string # Used to filter time range (required, format: date)
  --lt-created: string # Used to filter time range (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/expenses/highest_amount"
    query: [{name: gt_created, var: gt_created, required: true}, {name: lt_created, var: lt_created, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    gt_created: $gt_created, lt_created: $lt_created
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete expenses
#
# DELETE /expenses/sendEmails
# Returns: record<data: list<string>, success: bool>
# operationId: sendEmailsExpenses
export def "send-emails-expenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/expenses/sendEmails"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete expense
#
# DELETE /expenses/{expense_id}
# Returns: record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>
export def "delete-expenses-expense-id" [
  expense_id: string
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
    path: "/expenses/{expense_id}"
    path_params: [{name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show expense
#
# GET /expenses/{expense_id}
# Returns: record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>
export def "get-expenses-expense-id" [
  expense_id: string
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
    path: "/expenses/{expense_id}"
    path_params: [{name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit expense
#
# PUT /expenses/{expense_id}
# Returns: record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool>
export def "put-expenses-expense-id" [
  expense_id: string
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
    path: "/expenses/{expense_id}"
    path_params: [{name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of all OIOUBL files for the expense
#
# GET /expenses/{expense_id}/original_files
# Returns: record<success: bool>
export def "get-expenses-expense-id-original-files" [
  expense_id: string
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
    path: "/expenses/{expense_id}/original_files"
    path_params: [{name: expense_id, var: expense_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_id: $expense_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show OIOUBL file
#
# GET /expenses/{expense_id}/original_files/{file_id}
# Returns: record<success: bool>
export def "get-expenses-expense-id-original-files-file-id" [
  expense_id: string
  file_id: string
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
    path: "/expenses/{expense_id}/original_files/{file_id}"
    path_params: [{name: expense_id, var: expense_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    expense_id: $expense_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get general statistics
#
# GET /financial_statistics
# Returns: record<data: record<invoicedAmount: float, invoicedWorkingHours: string, notInvoicedAmount: float, notInvoicedWorkingHours: string, productsCosts: float, productsSales: float, rentalsCosts: float, rentalsSales: float, totalCosts: float, totalSales: float, workTimeCosts: float, workTimeSales: float>, success: bool>
# operationId: getFinancialStatistics
export def "get-financial-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
  --project-status-ids: string # format: uuid
  --only-not-invoiced: oneof<nothing, bool>
  --details: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}, {name: "project_status_ids[]", var: project_status_ids}, {name: only_not_invoiced, var: only_not_invoiced}, {name: details, var: details}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id, project_status_ids: $project_status_ids, only_not_invoiced: $only_not_invoiced, details: $details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get expenses sales price
#
# GET /financial_statistics/expensesSalesPrice
# Returns: record<expensesSalesPrice: float>
# operationId: getExpensesSalesPrice
export def "get-expenses-sales-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/expensesSalesPrice"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get invoiced amount
#
# GET /financial_statistics/invoicedAmount
# Returns: record<invoicedAmount: float>
# operationId: getInvoicedAmount
export def "get-invoiced-amount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/invoicedAmount"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get margin
#
# GET /financial_statistics/margin
# Returns: record<margin: float>
# operationId: getMargin
export def "get-margin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/margin"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get products material rentals cost price
#
# GET /financial_statistics/materialRentalsCostPrice
# Returns: record<materialRentalsCostPrice: float>
# operationId: getMaterialRentalsCostPrice
export def "get-material-rentals-cost-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/materialRentalsCostPrice"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get statistics overview
#
# GET /financial_statistics/overview
# Returns: record<data: record<expensesSalesPrice: float, invoicedAmount: float, margin: float, materialRentalsCostPrice: float, productsCostPrice: float, totalWorkingHours: string>, success: bool>
# operationId: getFinancialStatisticsOverview
export def "get-financial-statistics-overview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/overview"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get products cost price
#
# GET /financial_statistics/productsCostPrice
# Returns: record<productsCostPrice: float>
# operationId: getProductsCostPrice
export def "get-products-cost-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/productsCostPrice"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Total working hours grouped by time entry type
#
# GET /financial_statistics/workingHours
# Returns: record<normalWorkingHours: string, timeEntries: table<id: string, name: string, total: string>, totalWorkingHours: string>
export def "get-financial-statistics-working-hours" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/financial_statistics/workingHours"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of form field types
#
# GET /form_field_types
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-form-field-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the form_fields
  --identifier: string # Used to filter on the `identifier` of the form_fields
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/form_field_types"
    query: [{name: name, var: name}, {name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about single `FormField`
#
# GET /form_field_types/{form_field_type_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>
export def "get-form-field-types-form-field-type-id" [
  form_field_type_id: string
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
    path: "/form_field_types/{form_field_type_id}"
    path_params: [{name: form_field_type_id, var: form_field_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_field_type_id: $form_field_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new field to a `Form`
#
# POST /form_fields
# Returns: record<data: record<id: string>, success: bool>
export def "post-form-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --content-value: string
  --file-id: string # format: uuid
  --form-field-type-id: string # format: uuid
  --form-id: string # format: uuid
  --form-template-field-id: string # format: uuid
  --placement: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/form_fields"
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: content_value, var: content_value}, {name: file_id, var: file_id}, {name: form_field_type_id, var: form_field_type_id}, {name: form_id, var: form_id}, {name: form_template_field_id, var: form_template_field_id}, {name: placement, var: placement}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    comment: $comment, content_value: $content_value, file_id: $file_id, form_field_type_id: $form_field_type_id, form_id: $form_id, form_template_field_id: $form_template_field_id, placement: $placement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details about single `FormField`
#
# GET /form_fields/{form_field_id}
# Returns: record<data: record<comment: string, content_value: string, created: string, created_by_id: string, deleted: string, file_id: string, form_field_type_id: string, form_id: string, form_template_field_id: string, id: string, modified: string, placement: int>, success: bool>
export def "get-form-fields-form-field-id" [
  form_field_id: string
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
    path: "/form_fields/{form_field_id}"
    path_params: [{name: form_field_id, var: form_field_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_field_id: $form_field_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get array of form_templates for your company
#
# GET /form_templates
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-form-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the form_templates
  --identifier: string # Used to filter on the `identifier` of the form_templates
  --pdf-template-identifier: string # Used to filter on the `pdf_template_identifier` of the form_templates
  --description: string # Used to filter on the `description` of the form_templates
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/form_templates"
    query: [{name: name, var: name}, {name: identifier, var: identifier}, {name: pdf_template_identifier, var: pdf_template_identifier}, {name: description, var: description}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, identifier: $identifier, pdf_template_identifier: $pdf_template_identifier, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View one form template
#
# GET /form_templates/{form_template_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, success: bool>
export def "get-form-templates-form-template-id" [
  form_template_id: string
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
    path: "/form_templates/{form_template_id}"
    path_params: [{name: form_template_id, var: form_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_template_id: $form_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve array of forms
#
# GET /forms
# Returns: record<data: table<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extended: string@extended-completer # Used to have extended details from the forms from the `Form`'s `FormFields`
  --date-from: string # Used in conjunction with `date_to` to only show forms within these dates - format like `2016-28-05` (format: Y-m-d)
  --date-to: string # Used in conjunction with `date_from` to only show forms within these dates - format like `2016-28-30` (format: Y-m-d)
  --show: string # Used to show forms with trashed (format: with_trashed)
  --project-id: string # Used to filter on the `project_id` of the forms (format: uuid)
  --created-by-id: string # Used to filter on the `created_by_id` of the forms
  --form-template-id: list<string> # Used to filter on the `form_template_id` of the forms. Accept single value and array.
  --form-template-type: string # Filter by `form_templates.identifier` containing string passed in `form_template_type`. Accept strings like [`qa`, `dagseddel`]
  --employee-name: string # Used to filter forms by user's first or last name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/forms"
    query: [{name: extended, var: extended}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: show, var: show}, {name: project_id, var: project_id}, {name: created_by_id, var: created_by_id}, {name: form_template_id, var: form_template_id, style: csv}, {name: form_template_type, var: form_template_type}, {name: employee_name, var: employee_name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    extended: $extended, date_from: $date_from, date_to: $date_to, show: $show, project_id: $project_id, created_by_id: $created_by_id, form_template_id: $form_template_id, form_template_type: $form_template_type, employee_name: $employee_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new form
#
# POST /forms
# Returns: record<data: record<id: string>, success: bool>
export def "post-forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  form_template_id: string # format: uuid
  project_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forms"
    body: {content_type: "application/json", kind: json, fields: [{name: form_template_id, var: form_template_id}, {name: project_id, var: project_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    form_template_id: $form_template_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undelete form and related entities to it
#
# GET /forms/undelete/{form_id}
# Returns: record<data: list<string>, success: bool>
export def "get-forms-undelete-form-id" [
  form_id: string
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
    path: "/forms/undelete/{form_id}"
    path_params: [{name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate time form pdf
#
# GET /forms/view_time_form_pdf/{form_id}
# Returns: record<data: list<string>, success: bool>
export def "get-forms-view-time-form-pdf-form-id" [
  form_id: string
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
    path: "/forms/view_time_form_pdf/{form_id}"
    path_params: [{name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a form
#
# DELETE /forms/{form_id}
export def "delete-forms-form-id" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/forms/{form_id}"
    path_params: [{name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View form
#
# GET /forms/{form_id}
# Returns: record<data: record<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, success: bool>
export def "get-forms-form-id" [
  form_id: string
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
    path: "/forms/{form_id}"
    path_params: [{name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a form
#
# PUT /forms/{form_id}
export def "put-forms-form-id" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/forms/{form_id}"
    path_params: [{name: form_id, var: form_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integrations list
#
# GET /integrations
# Returns: record<status: string, success: bool>
# operationId: get-integrations-list
export def "get-integrations-list" [
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
    path: "/integrations"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate to Billys
#
# POST /integrations/billysAuthenticate
# Returns: record<accessToken: string>
export def "post-integrations-billys-authenticate" [
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
    path: "/integrations/billysAuthenticate"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force Synchronization with ERP systems
#
# GET /integrations/contactsSync
# Returns: record<status: string, success: bool>
# operationId: get-integrations-contactsSync
export def "get-integrations-contacts-sync" [
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
    path: "/integrations/contactsSync"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sync products from erp integration
#
# GET /integrations/productsSync
# Returns: record<success: bool>
export def "get-integrations-products-sync" [
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
    path: "/integrations/productsSync"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View integration details
#
# GET /integrations/{integration_id}
# Returns: record<status: string, success: bool>
# operationId: get-integrations-view
export def "get-integrations-view" [
  integration_id: string
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
    path: "/integrations/{integration_id}"
    path_params: [{name: integration_id, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of invoice line text templates
#
# GET /invoice_line_text_template
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-invoice-line-text-template" [
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
    path: "/invoice_line_text_template"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new invoice line text template
#
# POST /invoice_line_text_template
# Returns: record<data: record<id: string>, success: bool>
export def "post-invoice-line-text-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_line_text_template"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: html, var: html}, {name: image, var: image}], files: [image]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    html: $html, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an invoice line text template
#
# DELETE /invoice_line_text_template/{invoice_line_text_template_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-invoice-line-text-template-invoice-line-text-template-id" [
  invoice_line_text_template_id: string
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
    path: "/invoice_line_text_template/{invoice_line_text_template_id}"
    path_params: [{name: invoice_line_text_template_id, var: invoice_line_text_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_text_template_id: $invoice_line_text_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single invoice line text template
#
# GET /invoice_line_text_template/{invoice_line_text_template_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, success: bool>
export def "get-invoice-line-text-template-invoice-line-text-template-id" [
  invoice_line_text_template_id: string
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
    path: "/invoice_line_text_template/{invoice_line_text_template_id}"
    path_params: [{name: invoice_line_text_template_id, var: invoice_line_text_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_text_template_id: $invoice_line_text_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an invoice line text template
#
# POST /invoice_line_text_template/{invoice_line_text_template_id}
# Returns: record<data: list<string>, success: bool>
export def "post-invoice-line-text-template-invoice-line-text-template-id" [
  invoice_line_text_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_line_text_template/{invoice_line_text_template_id}"
    path_params: [{name: invoice_line_text_template_id, var: invoice_line_text_template_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: html, var: html}, {name: image, var: image}], files: [image]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_text_template_id: $invoice_line_text_template_id, html: $html, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add invoice line text
#
# POST /invoice_line_texts/
# Returns: record<data: record<id: string>, success: bool>
export def "post-invoice-line-texts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
  invoice_id: string # format: uuid
  --placement: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_line_texts/"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: html, var: html}, {name: image, var: image}, {name: invoice_id, var: invoice_id}, {name: placement, var: placement}], files: [image]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    html: $html, image: $image, invoice_id: $invoice_id, placement: $placement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit invoice line text
#
# POST /invoice_line_texts/{invoice_line_text_id}
# Returns: record<data: list<string>, success: bool>
export def "post-invoice-line-texts-invoice-line-text-id" [
  invoice_line_text_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_line_texts/{invoice_line_text_id}"
    path_params: [{name: invoice_line_text_id, var: invoice_line_text_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: html, var: html}, {name: image, var: image}], files: [image]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_text_id: $invoice_line_text_id, html: $html, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of invoice lines
#
# GET /invoice_lines
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-invoice-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoice-id: string # format: uuid
  --product-id: string # format: uuid
  --user-id: string # format: uuid
  --name: string
  --discount-text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invoice_lines"
    query: [{name: invoice_id, var: invoice_id}, {name: product_id, var: product_id}, {name: user_id, var: user_id}, {name: name, var: name}, {name: discount_text, var: discount_text}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, product_id: $product_id, user_id: $user_id, name: $name, discount_text: $discount_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add invoice line
#
# POST /invoice_lines
# Returns: record<data: record<id: string>, success: bool>
export def "post-invoice-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --child-invoice-lines: list
  --description: string
  --discount-percent: int # format: int32
  --discount-text: string
  --invoice-id: string # format: uuid
  --name: string
  --product-bundle-id: string # format: uuid
  --product-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoice_lines"
    body: {content_type: "application/json", kind: json, fields: [{name: child_invoice_lines, var: child_invoice_lines}, {name: description, var: description}, {name: discount_percent, var: discount_percent}, {name: discount_text, var: discount_text}, {name: invoice_id, var: invoice_id}, {name: name, var: name}, {name: product_bundle_id, var: product_bundle_id}, {name: product_id, var: product_id}, {name: quantity, var: quantity}, {name: selling_price, var: selling_price}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    child_invoice_lines: $child_invoice_lines, description: $description, discount_percent: $discount_percent, discount_text: $discount_text, invoice_id: $invoice_id, name: $name, product_bundle_id: $product_bundle_id, product_id: $product_id, quantity: $quantity, selling_price: $selling_price, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete invoice line
#
# DELETE /invoice_lines/{invoice_line_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-invoice-lines-invoice-line-id" [
  invoice_line_id: string
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
    path: "/invoice_lines/{invoice_line_id}"
    path_params: [{name: invoice_line_id, var: invoice_line_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_id: $invoice_line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View invoice line
#
# GET /invoice_lines/{invoice_line_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, success: bool>
export def "get-invoice-lines-invoice-line-id" [
  invoice_line_id: string
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
    path: "/invoice_lines/{invoice_line_id}"
    path_params: [{name: invoice_line_id, var: invoice_line_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_id: $invoice_line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit invoice line
#
# PUT /invoice_lines/{invoice_line_id}
# Returns: record<data: list<record>, success: bool>
export def "put-invoice-lines-invoice-line-id" [
  invoice_line_id: string
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
  --discount-percent: int # format: int32
  --discount-text: string
  --invoice-id: string # format: uuid
  --name: string
  --product-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --user-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/invoice_lines/{invoice_line_id}"
    path_params: [{name: invoice_line_id, var: invoice_line_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: discount_percent, var: discount_percent}, {name: discount_text, var: discount_text}, {name: invoice_id, var: invoice_id}, {name: name, var: name}, {name: product_id, var: product_id}, {name: quantity, var: quantity}, {name: selling_price, var: selling_price}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_line_id: $invoice_line_id, description: $description, discount_percent: $discount_percent, discount_text: $discount_text, invoice_id: $invoice_id, name: $name, product_id: $product_id, quantity: $quantity, selling_price: $selling_price, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of invoices
#
# GET /invoices
# Returns: record<data: table<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Used to filter on the `contact_id` of the invoices (format: uuid)
  --project-id: string # Used to filter on the `project_id` of the invoices (format: uuid)
  --invoice-number: string # Used to filter on the `invoice_number` of the invoices
  --offer-number: string
  --is-draft: int@is-draft-completer
  --is-offer: int@is-offer-completer
  --is-locked: int@is-locked-completer
  --is-fixed-price: int@is-fixed-price-completer
  --date-from: string # format: date
  --date-to: string # format: date
  --issued-date: string # format: date
  --sent-as-draft: int # Used to filter invoices which are sent as draft to integration
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/invoices"
    query: [{name: contact_id, var: contact_id}, {name: project_id, var: project_id}, {name: invoice_number, var: invoice_number}, {name: offer_number, var: offer_number}, {name: is_draft, var: is_draft}, {name: is_offer, var: is_offer}, {name: is_locked, var: is_locked}, {name: is_fixed_price, var: is_fixed_price}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: issued_date, var: issued_date}, {name: sent_as_draft, var: sent_as_draft}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    contact_id: $contact_id, project_id: $project_id, invoice_number: $invoice_number, offer_number: $offer_number, is_draft: $is_draft, is_offer: $is_offer, is_locked: $is_locked, is_fixed_price: $is_fixed_price, date_from: $date_from, date_to: $date_to, issued_date: $issued_date, sent_as_draft: $sent_as_draft
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add invoice
#
# POST /invoices
# Returns: record<data: record<id: string>, success: bool>
export def "post-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --created-or-modified-gte: string # format: date
  --date-from: string # format: date
  --date-to: string # format: date
  --erp-id: string
  --erp-payment-term-id: string
  --invoice-number: int # format: int32
  --is-draft: oneof<nothing, bool>
  --is-locked: oneof<nothing, bool>
  --is-offer: oneof<nothing, bool>
  --issued-date: string # format: date
  --message: string
  --offer-number: int # format: int32
  --payment-due-date: string # format: date
  --payment-term-id: string # format: uuid
  --project-id: string # format: uuid
  --reference: string
  --vat-percent: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices"
    body: {content_type: "application/json", kind: json, fields: [{name: contact_id, var: contact_id}, {name: created_or_modified_gte, var: created_or_modified_gte}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: erp_id, var: erp_id}, {name: erp_payment_term_id, var: erp_payment_term_id}, {name: invoice_number, var: invoice_number}, {name: is_draft, var: is_draft}, {name: is_locked, var: is_locked}, {name: is_offer, var: is_offer}, {name: issued_date, var: issued_date}, {name: message, var: message}, {name: offer_number, var: offer_number}, {name: payment_due_date, var: payment_due_date}, {name: payment_term_id, var: payment_term_id}, {name: project_id, var: project_id}, {name: reference, var: reference}, {name: vat_percent, var: vat_percent}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    contact_id: $contact_id, created_or_modified_gte: $created_or_modified_gte, date_from: $date_from, date_to: $date_to, erp_id: $erp_id, erp_payment_term_id: $erp_payment_term_id, invoice_number: $invoice_number, is_draft: $is_draft, is_locked: $is_locked, is_offer: $is_offer, issued_date: $issued_date, message: $message, offer_number: $offer_number, payment_due_date: $payment_due_date, payment_term_id: $payment_term_id, project_id: $project_id, reference: $reference, vat_percent: $vat_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete invoices
#
# DELETE /invoices/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteInvoices
export def "bulk-delete-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/invoices/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List VAT options
#
# GET /invoices/vatOptions
# Returns: record<success: bool>
export def "get-invoices-vat-options" [
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
    path: "/invoices/vatOptions"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete invoice
#
# DELETE /invoices/{invoice_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-invoices-invoice-id" [
  invoice_id: string
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
    path: "/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View invoice
#
# GET /invoices/{invoice_id}
# Returns: record<data: record<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, success: bool>
export def "get-invoices-invoice-id" [
  invoice_id: string
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
    path: "/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit invoice
#
# PUT /invoices/{invoice_id}
# Returns: record<data: list<record>, success: bool>
export def "put-invoices-invoice-id" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --date-from: string # format: date
  --date-to: string # format: date
  --erp-id: string
  --erp-payment-term-id: string
  --invoice-number: int # format: int32
  --is-draft: oneof<nothing, bool>
  --is-locked: oneof<nothing, bool>
  --is-offer: oneof<nothing, bool>
  --issued-date: string # format: date
  --message: string
  --offer-number: int # format: int32
  --payment-due-date: string # format: date
  --payment-term-id: string # format: uuid
  --project-id: string # format: uuid
  --reference: string
  --vat-percent: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/invoices/{invoice_id}"
    path_params: [{name: invoice_id, var: invoice_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contact_id, var: contact_id}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: erp_id, var: erp_id}, {name: erp_payment_term_id, var: erp_payment_term_id}, {name: invoice_number, var: invoice_number}, {name: is_draft, var: is_draft}, {name: is_locked, var: is_locked}, {name: is_offer, var: is_offer}, {name: issued_date, var: issued_date}, {name: message, var: message}, {name: offer_number, var: offer_number}, {name: payment_due_date, var: payment_due_date}, {name: payment_term_id, var: payment_term_id}, {name: project_id, var: project_id}, {name: reference, var: reference}, {name: vat_percent, var: vat_percent}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, contact_id: $contact_id, date_from: $date_from, date_to: $date_to, erp_id: $erp_id, erp_payment_term_id: $erp_payment_term_id, invoice_number: $invoice_number, is_draft: $is_draft, is_locked: $is_locked, is_offer: $is_offer, issued_date: $issued_date, message: $message, offer_number: $offer_number, payment_due_date: $payment_due_date, payment_term_id: $payment_term_id, project_id: $project_id, reference: $reference, vat_percent: $vat_percent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a copy of an invoice
#
# POST /invoices/{invoice_id}/copy
# Returns: record<data: record<id: string>, success: bool>
export def "post-invoices-invoice-id-copy" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # format: uuid
  --contact-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/invoices/{invoice_id}/copy"
    path_params: [{name: invoice_id, var: invoice_id}]
    query: [{name: project_id, var: project_id}, {name: contact_id, var: contact_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, project_id: $project_id, contact_id: $contact_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an invoice emails
#
# GET /invoices/{invoice_id}/emails/{email_id}
# Returns: record<data: record<api_response: string, body: string, carbon_copy: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_sent: bool, modified: string, recipients: string, reply_to: string, subject: string>, success: bool>
# operationId: getOneInvoiceEmails
export def "get-one-invoice-emails" [
  invoice_id: string
  email_id: string
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
    path: "/invoices/{invoice_id}/emails/{email_id}"
    path_params: [{name: invoice_id, var: invoice_id}, {name: email_id, var: email_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of invoice files
#
# GET /invoices/{invoice_id}/files
# Returns: record<data: table<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
# operationId: getInvoiceFiles
export def "get-invoice-files" [
  invoice_id: string
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
    path: "/invoices/{invoice_id}/files"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new invoice file
#
# POST /invoices/{invoice_id}/files
# Returns: record<data: record<id: string>, success: bool>
# operationId: createInvoiceFile
export def "create-invoice-file" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # format: uuid
  --body-invoice-id: string # format: uuid (spec name: invoice_id)
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invoices/{invoice_id}/files"
    path_params: [{name: invoice_id, var: invoice_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file_id, var: file_id}, {name: invoice_id, var: body_invoice_id, required: true}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, file_id: $file_id, body_invoice_id: $body_invoice_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete invoice file
#
# DELETE /invoices/{invoice_id}/files/{file_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-invoices-invoice-id-files-file-id" [
  invoice_id: string
  file_id: string
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
    path: "/invoices/{invoice_id}/files/{file_id}"
    path_params: [{name: invoice_id, var: invoice_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an invoice files
#
# GET /invoices/{invoice_id}/files/{file_id}
# Returns: record<data: record<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, success: bool>
# operationId: getOneInvoiceFiles
export def "get-one-invoice-files" [
  invoice_id: string
  file_id: string
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
    path: "/invoices/{invoice_id}/files/{file_id}"
    path_params: [{name: invoice_id, var: invoice_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an invoice file containing the project's pdf overview
#
# POST /invoices/{invoice_id}/linkProjectPdf
# Returns: record<data: list<string>, success: bool>
export def "post-invoices-invoice-id-link-project-pdf" [
  invoice_id: string
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
    path: "/invoices/{invoice_id}/linkProjectPdf"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the linked project overview pdf
#
# POST /invoices/{invoice_id}/unlinkProjectPdf
# Returns: record<data: list<string>, success: bool>
export def "post-invoices-invoice-id-unlink-project-pdf" [
  invoice_id: string
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
    path: "/invoices/{invoice_id}/unlinkProjectPdf"
    path_params: [{name: invoice_id, var: invoice_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of mass messages for specific user
#
# GET /mass_messages_users
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-mass-messages-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-read: oneof<nothing, bool> # Used to filter on the `is_read` of the mass messages
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mass_messages_users"
    query: [{name: is_read, var: is_read}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    is_read: $is_read
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View mass message
#
# GET /mass_messages_users/{mass_messages_user_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record<company_id: string, content: string, created: string, created_by_id: string, deleted: string, id: string, modified: string>, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, success: bool>
export def "get-mass-messages-users-mass-messages-user-id" [
  mass_messages_user_id: string
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
    path: "/mass_messages_users/{mass_messages_user_id}"
    path_params: [{name: mass_messages_user_id, var: mass_messages_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    mass_messages_user_id: $mass_messages_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit mass message
#
# PUT /mass_messages_users/{mass_messages_user_id}
# Returns: record<data: list<record>, success: bool>
export def "put-mass-messages-users-mass-messages-user-id" [
  mass_messages_user_id: string
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
    path: "/mass_messages_users/{mass_messages_user_id}"
    path_params: [{name: mass_messages_user_id, var: mass_messages_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    mass_messages_user_id: $mass_messages_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of all materials
#
# GET /materials
# Returns: record<data: table<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-materials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string # Used to filter on the `barcode` of the materials
  --name: string # Used to filter on the `name` of the materials
  --project-id: string # Used to find materials used in specific project by `project_id` (format: uuid)
  --currently-rented: oneof<nothing, bool> # Used to find currently rented materials
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/materials"
    query: [{name: barcode, var: barcode}, {name: name, var: name}, {name: project_id, var: project_id}, {name: currently_rented, var: currently_rented}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    barcode: $barcode, name: $name, project_id: $project_id, currently_rented: $currently_rented
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add material
#
# POST /materials
# Returns: record<data: record<id: string>, success: bool>
export def "post-materials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string
  --billing-cysle: string@billing-cysle-completer
  --cost-price: float # format: float
  --description: string
  --is-single-usage: oneof<nothing, bool>
  --name: string
  --selling-price: float # format: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/materials"
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: barcode}, {name: billing_cysle, var: billing_cysle}, {name: cost_price, var: cost_price}, {name: description, var: description}, {name: is_single_usage, var: is_single_usage}, {name: name, var: name}, {name: selling_price, var: selling_price}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    barcode: $barcode, billing_cysle: $billing_cysle, cost_price: $cost_price, description: $description, is_single_usage: $is_single_usage, name: $name, selling_price: $selling_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete material
#
# DELETE /materials/{material_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-materials-material-id" [
  material_id: string
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
    path: "/materials/{material_id}"
    path_params: [{name: material_id, var: material_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View material
#
# GET /materials/{material_id}
# Returns: record<data: record<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, success: bool>
export def "get-materials-material-id" [
  material_id: string
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
    path: "/materials/{material_id}"
    path_params: [{name: material_id, var: material_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit material
#
# PUT /materials/{material_id}
# Returns: record<data: list<record>, success: bool>
export def "put-materials-material-id" [
  material_id: string
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
    path: "/materials/{material_id}"
    path_params: [{name: material_id, var: material_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of rentals for specific material
#
# GET /materials/{material_id}/rentals/
# Returns: record<data: table<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-materials-material-id-rentals" [
  material_id: string
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
    path: "/materials/{material_id}/rentals/"
    path_params: [{name: material_id, var: material_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add material rental
#
# POST /materials/{material_id}/rentals/
# Returns: record<data: record<id: string>, success: bool>
export def "post-materials-material-id-rentals" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-date: string # format: dateTime
  --is-invoiced: string # format: dateTime
  --body-material-id: string # format: uuid (spec name: material_id)
  --project-id: string # format: uuid
  --quantity: float # format: float
  --to-date: string # format: dateTime
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/materials/{material_id}/rentals/"
    path_params: [{name: material_id, var: material_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: form_id, var: form_id}, {name: from_date, var: from_date}, {name: is_invoiced, var: is_invoiced}, {name: material_id, var: body_material_id}, {name: project_id, var: project_id}, {name: quantity, var: quantity}, {name: to_date, var: to_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    material_id: $material_id, form_id: $form_id, from_date: $from_date, is_invoiced: $is_invoiced, body_material_id: $body_material_id, project_id: $project_id, quantity: $quantity, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checkout material rental
#
# POST /materials/{material_id}/rentals/checkout/
# Returns: record<data: record<id: string>, success: bool>
export def "post-materials-material-id-rentals-checkout" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --material-rental-id: string # format: uuid
  --to-date: string # format: dateTime
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/materials/{material_id}/rentals/checkout/"
    path_params: [{name: material_id, var: material_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: form_id, var: form_id}, {name: material_rental_id, var: material_rental_id}, {name: to_date, var: to_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    material_id: $material_id, form_id: $form_id, material_rental_id: $material_rental_id, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete material rental
#
# DELETE /materials/{material_id}/rentals/{material_rental_id}/
# Returns: record<data: record, success: bool>
export def "delete-materials-material-id-rentals-material-rental-id" [
  material_id: string
  material_rental_id: string
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
    path: "/materials/{material_id}/rentals/{material_rental_id}/"
    path_params: [{name: material_id, var: material_id}, {name: material_rental_id, var: material_rental_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id, material_rental_id: $material_rental_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show rental foor materi
#
# GET /materials/{material_id}/rentals/{material_rental_id}/
# Returns: record<data: record<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, success: bool>
export def "get-materials-material-id-rentals-material-rental-id" [
  material_id: string
  material_rental_id: string
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
    path: "/materials/{material_id}/rentals/{material_rental_id}/"
    path_params: [{name: material_id, var: material_id}, {name: material_rental_id, var: material_rental_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id, material_rental_id: $material_rental_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit material rental
#
# PUT /materials/{material_id}/rentals/{material_rental_id}/
# Returns: record<data: record, success: bool>
export def "put-materials-material-id-rentals-material-rental-id" [
  material_id: string
  material_rental_id: string
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
    path: "/materials/{material_id}/rentals/{material_rental_id}/"
    path_params: [{name: material_id, var: material_id}, {name: material_rental_id, var: material_rental_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    material_id: $material_id, material_rental_id: $material_rental_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of offer statuses
#
# GET /offer_statuses
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-offer-statuses" [
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
    path: "/offer_statuses"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new offer status
#
# POST /offer_statuses
# Returns: record<data: list<string>, success: bool>
export def "post-offer-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --description: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offer_statuses"
    body: {content_type: "application/json", kind: json, fields: [{name: company_id, var: company_id}, {name: description, var: description}, {name: identifier, var: identifier}, {name: is_custom, var: is_custom}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    company_id: $company_id, description: $description, identifier: $identifier, is_custom: $is_custom, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete offer statuses
#
# DELETE /offer_statuses/bulkDelete
# Returns: record<data: list<string>, success: bool>
export def "delete-offer-statuses-bulk-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/offer_statuses/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a offer status
#
# DELETE /offer_statuses/{offer_status_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-offer-statuses-offer-status-id" [
  offer_status_id: string
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
    path: "/offer_statuses/{offer_status_id}"
    path_params: [{name: offer_status_id, var: offer_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_status_id: $offer_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single offer status
#
# GET /offer_statuses/{offer_status_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, success: bool>
export def "get-offer-statuses-offer-status-id" [
  offer_status_id: string
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
    path: "/offer_statuses/{offer_status_id}"
    path_params: [{name: offer_status_id, var: offer_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_status_id: $offer_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a offer status
#
# PUT /offer_statuses/{offer_status_id}
# Returns: record<data: list<string>, success: bool>
export def "put-offer-statuses-offer-status-id" [
  offer_status_id: string
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
    path: "/offer_statuses/{offer_status_id}"
    path_params: [{name: offer_status_id, var: offer_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_status_id: $offer_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of offers
#
# GET /offers
# Returns: record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-offers" [
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
    path: "/offers"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new offer
#
# POST /offers
# Returns: record<data: record<id: string>, success: bool>
export def "post-offers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offer-lines: list
  --project-id: string # format: uuid
  --status: string@status-completer-1 # default: draft
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/offers"
    body: {content_type: "application/json", kind: json, fields: [{name: offer_lines, var: offer_lines}, {name: project_id, var: project_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    offer_lines: $offer_lines, project_id: $project_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an offer
#
# DELETE /offers/{offer_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-offers-offer-id" [
  offer_id: string
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
    path: "/offers/{offer_id}"
    path_params: [{name: offer_id, var: offer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_id: $offer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View offer
#
# GET /offers/{offer_id}
# Returns: record<data: record<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool>
export def "get-offers-offer-id" [
  offer_id: string
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
    path: "/offers/{offer_id}"
    path_params: [{name: offer_id, var: offer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_id: $offer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an offer
#
# PUT /offers/{offer_id}
# Returns: record<data: list<string>, success: bool>
export def "put-offers-offer-id" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # default: draft
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/offers/{offer_id}"
    path_params: [{name: offer_id, var: offer_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_id: $offer_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of changelog history for the offer. Returns offer object with contact and user objects if they are provided
#
# GET /offers/{offer_id}/changelog
# Returns: record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool>
export def "get-offers-offer-id-changelog" [
  offer_id: string
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
    path: "/offers/{offer_id}/changelog"
    path_params: [{name: offer_id, var: offer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    offer_id: $offer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a statistics data for rejection reasons
#
# GET /overview/rejection_reasons
# Returns: record<data: list<any>, success: bool>
export def "get-overview-rejection-reasons" [
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
    path: "/overview/rejection_reasons"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of payment term types
#
# GET /payment_term_types
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-payment-term-types" [
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
    path: "/payment_term_types"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 payment term type
#
# GET /payment_term_types/{payment_term_type_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool>
export def "get-payment-term-types-payment-term-type-id" [
  payment_term_type_id: string
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
    path: "/payment_term_types/{payment_term_type_id}"
    path_params: [{name: payment_term_type_id, var: payment_term_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    payment_term_type_id: $payment_term_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of payment terms
#
# GET /payment_terms
# Returns: record<data: table<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-payment-terms" [
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
    path: "/payment_terms"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get integration payment terms list
#
# GET /payment_terms/erp
# Returns: record<data: table<daysOfCredit: int, id: string, name: string, pretty_string: string, type: string>, success: bool>
export def "get-payment-terms-erp" [
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
    path: "/payment_terms/erp"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 payment term
#
# GET /payment_terms/{payment_term_id}
# Returns: record<data: record<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, success: bool>
export def "get-payment-terms-payment-term-id" [
  payment_term_id: string
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
    path: "/payment_terms/{payment_term_id}"
    path_params: [{name: payment_term_id, var: payment_term_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    payment_term_id: $payment_term_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if API is up and API key works
#
# GET /ping
# Returns: record<status: string>
export def "get-ping" [
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
    path: "/ping"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List products
#
# GET /products
# Returns: record<data: table<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the products
  --product-number: string # Used to filter on the `product_number` of the products (format: uuid)
  --barcode: string # Used to filter on the `barcode` of the products
  --modified-gte: string # format: datetime
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products"
    query: [{name: name, var: name}, {name: product_number, var: product_number}, {name: barcode, var: barcode}, {name: modified_gte, var: modified_gte}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, product_number: $product_number, barcode: $barcode, modified_gte: $modified_gte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new product
#
# POST /products
# Returns: record<data: record<id: string>, success: bool>
export def "post-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string
  --buying-price: float # format: double
  --description: string
  --erp-id: string
  name: string
  --product-number: string
  --selling-price: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products"
    body: {content_type: "application/json", kind: json, fields: [{name: barcode, var: barcode}, {name: buying_price, var: buying_price}, {name: description, var: description}, {name: erp_id, var: erp_id}, {name: name, var: name}, {name: product_number, var: product_number}, {name: selling_price, var: selling_price}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    barcode: $barcode, buying_price: $buying_price, description: $description, erp_id: $erp_id, name: $name, product_number: $product_number, selling_price: $selling_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete products
#
# DELETE /products/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteProducts
export def "bulk-delete-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/products/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore a deleted product
#
# POST /products/undelete/{product_id}
# Returns: record<data: list<string>, success: bool>
export def "post-products-undelete-product-id" [
  product_id: string
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
    path: "/products/undelete/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product
#
# DELETE /products/{product_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-products-product-id" [
  product_id: string
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
    path: "/products/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View single product
#
# GET /products/{product_id}
# Returns: record<data: record<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, success: bool>
export def "get-products-product-id" [
  product_id: string
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
    path: "/products/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a product
#
# PUT /products/{product_id}
# Returns: record<data: list<record>, success: bool>
export def "put-products-product-id" [
  product_id: string
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
    path: "/products/{product_id}"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload or delete product image
#
# POST /products/{product_id}/uploadImage
# operationId: Upload or delete product image
export def "upload-or-delete-product-image" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/products/{product_id}/uploadImage"
    path_params: [{name: product_id, var: product_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: image, var: image}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a product's variants
#
# GET /products/{product_id}/variants
# Returns: record<data: table<name: string, price: float, product_number: string, variant_id: string, variant_type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-products-product-id-variants" [
  product_id: string
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
    path: "/products/{product_id}/variants"
    path_params: [{name: product_id, var: product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new variant to a product
#
# POST /products/{product_id}/variants
# Returns: record<data: list<string>, success: bool>
export def "post-products-product-id-variants" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filters by name
  ratio: float
  variant_id: string # format: uuid
  variant_type: string@variant-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{product_id}/variants"
    path_params: [{name: product_id, var: product_id}]
    query: [{name: name, var: name}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ratio, var: ratio}, {name: variant_id, var: variant_id}, {name: variant_type, var: variant_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id, name: $name, ratio: $ratio, variant_id: $variant_id, variant_type: $variant_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a product variant
#
# DELETE /products/{product_id}/variants/{variant_type}/{variant_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-products-product-id-variants-variant-type-variant-id" [
  product_id: string
  variant_type: string@variant-type-completer
  variant_id: string
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
    path: "/products/{product_id}/variants/{variant_type}/{variant_id}"
    path_params: [{name: product_id, var: product_id}, {name: variant_type, var: variant_type}, {name: variant_id, var: variant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    product_id: $product_id, variant_type: $variant_type, variant_id: $variant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project custom field attributes
#
# GET /project_custom_field_attributes
# Returns: record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-project-custom-field-attributes" [
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
    path: "/project_custom_field_attributes"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 project custom field attribute
#
# GET /project_custom_field_attributes/{project_custom_field_attribute_id}
# Returns: record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>
export def "get-project-custom-field-attributes-project-custom-field-attribute-id" [
  project_custom_field_attribute_id: string
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
    path: "/project_custom_field_attributes/{project_custom_field_attribute_id}"
    path_params: [{name: project_custom_field_attribute_id, var: project_custom_field_attribute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_custom_field_attribute_id: $project_custom_field_attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project status types
#
# GET /project_status_types
# Returns: record<data: table<_locale: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-project-status-types" [
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
    path: "/project_status_types"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of project statuses
#
# GET /project_statuses
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-project-statuses" [
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
    path: "/project_statuses"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project status
#
# POST /project_statuses
# Returns: record<data: record<id: string>, success: bool>
export def "post-project-statuses" [
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
  --name: string
  --project-status-type-id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/project_statuses"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: project_status_type_id, var: project_status_type_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    description: $description, name: $name, project_status_type_id: $project_status_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add default project statuses to company
#
# POST /project_statuses/add_default
# Returns: record<message: string, success: bool>
export def "post-project-statuses-add-default" [
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
    path: "/project_statuses/add_default"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete project statuses
#
# DELETE /project_statuses/bulkDelete
# Returns: record<data: list<string>, success: bool>
export def "delete-project-statuses-bulk-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/project_statuses/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project status
#
# DELETE /project_statuses/{project_status_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-project-statuses-project-status-id" [
  project_status_id: string
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
    path: "/project_statuses/{project_status_id}"
    path_params: [{name: project_status_id, var: project_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single project status
#
# GET /project_statuses/{project_status_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool>
export def "get-project-statuses-project-status-id" [
  project_status_id: string
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
    path: "/project_statuses/{project_status_id}"
    path_params: [{name: project_status_id, var: project_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a project status
#
# PUT /project_statuses/{project_status_id}
# Returns: record<data: list<string>, success: bool>
export def "put-project-statuses-project-status-id" [
  project_status_id: string
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
    path: "/project_statuses/{project_status_id}"
    path_params: [{name: project_status_id, var: project_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_status_id: $project_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of projects
#
# GET /projects
# Returns: record<data: table<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
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
  --show-all: oneof<nothing, bool> # Unless this is set to `true` only open projects will be shown (default: false)
  --sort: string # Sort projects by `not_invoiced_amount`
  --direction: string
  --contact-id: string # Used to filter on the `contact_id` of the projects (format: uuid)
  --company-id: string # Used to filter on the `company_id` of the projects (format: uuid)
  --project-status-id: string # Used to filter on the `project_status_id` of the projects (format: uuid)
  --project-status-ids: list<string> # Used to filter on the `project_status_id` of the projects (match any of the provided values)
  --name: string # Used to search on the `name` of the projects
  --erp-project-id: string # Used to search on the `erp_project_id` of the projects
  --erp-task-id: string # Used to search on the `erp_task_id` of the projects
  --start-time-gte: string # Show projects with start time after than this value
  --start-time-lte: string # Show projects with start time before this value
  --start-time-eq: string # Show only projects with start time on specific date
  --event-start-gt: string # format: datetime
  --event-start-lt: string # format: datetime
  --event-start-eq: string # format: datetime
  --event-end-gt: string # format: datetime
  --event-end-lt: string # format: datetime
  --event-end-eq: string # format: datetime
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: show_all, var: show_all}, {name: sort, var: sort}, {name: direction, var: direction}, {name: contact_id, var: contact_id}, {name: company_id, var: company_id}, {name: project_status_id, var: project_status_id}, {name: project_status_ids, var: project_status_ids, style: csv}, {name: name, var: name}, {name: erp_project_id, var: erp_project_id}, {name: erp_task_id, var: erp_task_id}, {name: start_time_gte, var: start_time_gte}, {name: start_time_lte, var: start_time_lte}, {name: start_time_eq, var: start_time_eq}, {name: "event_start[][gt]", var: event_start_gt}, {name: "event_start[][lt]", var: event_start_lt}, {name: "event_start[][eq]", var: event_start_eq}, {name: "event_end[][gt]", var: event_end_gt}, {name: "event_end[][lt]", var: event_end_lt}, {name: "event_end[][eq]", var: event_end_eq}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    show_all: $show_all, sort: $sort, direction: $direction, contact_id: $contact_id, company_id: $company_id, project_status_id: $project_status_id, project_status_ids: $project_status_ids, name: $name, erp_project_id: $erp_project_id, erp_task_id: $erp_task_id, start_time_gte: $start_time_gte, start_time_lte: $start_time_lte, start_time_eq: $start_time_eq, event_start_gt: $event_start_gt, event_start_lt: $event_start_lt, event_start_eq: $event_start_eq, event_end_gt: $event_end_gt, event_end_lt: $event_end_lt, event_end_eq: $event_end_eq
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a project
#
# POST /projects
# Returns: record<data: record<id: string>, success: bool>
export def "post-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --child-projects: list
  --city-id: string # format: uuid
  --contact-id: string # format: uuid
  --description: string
  --erp-project-id: string
  --erp-task-id: string
  name: string
  --parent-id: string # format: uuid
  --project-status-id: string # format: uuid
  --start-time: string # format: datetime
  --street-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: child_projects, var: child_projects}, {name: city_id, var: city_id}, {name: contact_id, var: contact_id}, {name: description, var: description}, {name: erp_project_id, var: erp_project_id}, {name: erp_task_id, var: erp_task_id}, {name: name, var: name}, {name: parent_id, var: parent_id}, {name: project_status_id, var: project_status_id}, {name: start_time, var: start_time}, {name: street_name, var: street_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    child_projects: $child_projects, city_id: $city_id, contact_id: $contact_id, description: $description, erp_project_id: $erp_project_id, erp_task_id: $erp_task_id, name: $name, parent_id: $parent_id, project_status_id: $project_status_id, start_time: $start_time, street_name: $street_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the company has projects with custom statuses
#
# GET /projects/has_projects_with_custom_statuses
# Returns: record<has_custom_statuses: bool, success: bool>
export def "get-projects-has-projects-with-custom-statuses" [
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
    path: "/projects/has_projects_with_custom_statuses"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /projects/{project_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-projects-project-id" [
  project_id: string
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
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View specific project
#
# GET /projects/{project_id}
# Returns: record<data: record<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, success: bool>
export def "get-projects-project-id" [
  project_id: string
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
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a project
#
# PUT /projects/{project_id}
# Returns: record<data: list<record>, success: bool>
export def "put-projects-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --description: string
  --erp-project-id: string
  --erp-task-id: string
  name: string
  --project-status-id: string # format: uuid
  --start-time: string # format: datetime
  --street-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{project_id}"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contact_id, var: contact_id}, {name: description, var: description}, {name: erp_project_id, var: erp_project_id}, {name: erp_task_id, var: erp_task_id}, {name: name, var: name}, {name: project_status_id, var: project_status_id}, {name: start_time, var: start_time}, {name: street_name, var: street_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, contact_id: $contact_id, description: $description, erp_project_id: $erp_project_id, erp_task_id: $erp_task_id, name: $name, project_status_id: $project_status_id, start_time: $start_time, street_name: $street_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of all files uploaded to project
#
# GET /projects/{project_id}/all_files
# Returns: record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-projects-project-id-all-files" [
  project_id: string
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
    path: "/projects/{project_id}/all_files"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of files uploaded to project
#
# GET /projects/{project_id}/files
# Returns: record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-projects-project-id-files" [
  project_id: string
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
    path: "/projects/{project_id}/files"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete file
#
# DELETE /projects/{project_id}/files/{file_id}/
# Returns: record<data: record, success: bool>
export def "delete-projects-project-id-files-file-id" [
  project_id: string
  file_id: string
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
    path: "/projects/{project_id}/files/{file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show file
#
# GET /projects/{project_id}/files/{file_id}/
# Returns: record<data: record, success: bool>
export def "get-projects-project-id-files-file-id" [
  project_id: string
  file_id: string
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
    path: "/projects/{project_id}/files/{file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit file
#
# PUT /projects/{project_id}/files/{file_id}/
# Returns: record<data: record, success: bool>
export def "put-projects-project-id-files-file-id" [
  project_id: string
  file_id: string
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
    path: "/projects/{project_id}/files/{file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of project files uploaded to project
#
# GET /projects/{project_id}/project_files
# Returns: record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-projects-project-id-project-files" [
  project_id: string
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
    path: "/projects/{project_id}/project_files"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add project file to projects
#
# POST /projects/{project_id}/project_files
# Returns: record<data: record<id: string>, success: bool>
export def "post-projects-project-id-project-files" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_id}/project_files"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    project_id: $project_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project file
#
# DELETE /projects/{project_id}/project_files/{project_file_id}/
# Returns: record<data: record, success: bool>
export def "delete-projects-project-id-project-files-project-file-id" [
  project_id: string
  project_file_id: string
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
    path: "/projects/{project_id}/project_files/{project_file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: project_file_id, var: project_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, project_file_id: $project_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show project file
#
# GET /projects/{project_id}/project_files/{project_file_id}/
# Returns: record<data: record, success: bool>
export def "get-projects-project-id-project-files-project-file-id" [
  project_id: string
  project_file_id: string
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
    path: "/projects/{project_id}/project_files/{project_file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: project_file_id, var: project_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, project_file_id: $project_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit project file
#
# PUT /projects/{project_id}/project_files/{project_file_id}/
# Returns: record<data: record, success: bool>
export def "put-projects-project-id-project-files-project-file-id" [
  project_id: string
  project_file_id: string
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
    path: "/projects/{project_id}/project_files/{project_file_id}/"
    path_params: [{name: project_id, var: project_id}, {name: project_file_id, var: project_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, project_file_id: $project_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send bulk forms pdf by email
#
# POST /projects/{project_id}/send_bulk_pdf
# Returns: record<data: list<string>, success: bool>
export def "post-projects-project-id-send-bulk-pdf" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_id}/send_bulk_pdf"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: form_id, var: form_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, form_id: $form_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show list of users added to project
#
# GET /projects/{project_id}/users/
# Returns: record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-projects-project-id-users" [
  project_id: string
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
    path: "/projects/{project_id}/users/"
    path_params: [{name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user to project
#
# POST /projects/{project_id}/users/
# Returns: record<data: record<id: string>, success: bool>
export def "post-projects-project-id-users" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_id}/users/"
    path_params: [{name: project_id, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user from project
#
# DELETE /projects/{project_id}/users/{user_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-projects-project-id-users-user-id" [
  project_id: string
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
    path: "/projects/{project_id}/users/{user_id}"
    path_params: [{name: project_id, var: project_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View specific user assigned to project
#
# GET /projects/{project_id}/users/{user_id}
# Returns: record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool>
export def "get-projects-project-id-users-user-id" [
  project_id: string
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
    path: "/projects/{project_id}/users/{user_id}"
    path_params: [{name: project_id, var: project_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of report types
#
# GET /reports
export def "get-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/reports"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of roles
#
# GET /roles
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List stock_locations
#
# GET /stock_locations
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-stock-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the stock_locations
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stock_locations"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new stock_locations
#
# POST /stock_locations
# Returns: record<data: record<id: string>, success: bool>
export def "post-stock-locations" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stock_locations"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete location
#
# DELETE /stock_locations/{location_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-stock-locations-location-id" [
  location_id: string
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
    path: "/stock_locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View single location
#
# GET /stock_locations/{location_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, success: bool>
export def "get-stock-locations-location-id" [
  location_id: string
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
    path: "/stock_locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit location
#
# PUT /stock_locations/{location_id}
# Returns: record<data: list<record>, success: bool>
export def "put-stock-locations-location-id" [
  location_id: string
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
    path: "/stock_locations/{location_id}"
    path_params: [{name: location_id, var: location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List time entries
#
# GET /time_entries
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
  --form-id: string
  --project-id: string
  --gt-from-time: string
  --lt-from-time: string
  --gt-to-time: string
  --lt-to-time: string
  --lt-sum: string
  --gt-sum: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/time_entries"
    query: [{name: user_id, var: user_id}, {name: form_id, var: form_id}, {name: project_id, var: project_id}, {name: gt_from_time, var: gt_from_time}, {name: lt_from_time, var: lt_from_time}, {name: gt_to_time, var: gt_to_time}, {name: lt_to_time, var: lt_to_time}, {name: lt_sum, var: lt_sum}, {name: gt_sum, var: gt_sum}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, form_id: $form_id, project_id: $project_id, gt_from_time: $gt_from_time, lt_from_time: $lt_from_time, gt_to_time: $gt_to_time, lt_to_time: $lt_to_time, lt_sum: $lt_sum, gt_sum: $gt_sum
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new time entry
#
# POST /time_entries
# Returns: record<data: record<id: string>, success: bool>
export def "post-time-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-time: string # format: dateTime
  --is-all-day: oneof<nothing, bool>
  --project-id: string # format: uuid
  --sum: int # Amount of seconds - should only be included when using is_all_day, otherwise will be calculated from from_time and to_time (format: int32)
  time_entry_type_id: string # format: uuid
  --to-time: string # format: dateTime
  user_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/time_entries"
    body: {content_type: "application/json", kind: json, fields: [{name: form_id, var: form_id}, {name: from_time, var: from_time}, {name: is_all_day, var: is_all_day}, {name: project_id, var: project_id}, {name: sum, var: sum}, {name: time_entry_type_id, var: time_entry_type_id}, {name: to_time, var: to_time}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    form_id: $form_id, from_time: $from_time, is_all_day: $is_all_day, project_id: $project_id, sum: $sum, time_entry_type_id: $time_entry_type_id, to_time: $to_time, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete time entry
#
# DELETE /time_entries/{time_entry_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-time-entries-time-entry-id" [
  time_entry_id: string
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
    path: "/time_entries/{time_entry_id}"
    path_params: [{name: time_entry_id, var: time_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_id: $time_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry
#
# GET /time_entries/{time_entry_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, success: bool>
export def "get-time-entries-time-entry-id" [
  time_entry_id: string
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
    path: "/time_entries/{time_entry_id}"
    path_params: [{name: time_entry_id, var: time_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_id: $time_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit time entry
#
# PUT /time_entries/{time_entry_id}
# Returns: record<data: list<record>, success: bool>
export def "put-time-entries-time-entry-id" [
  time_entry_id: string
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
    path: "/time_entries/{time_entry_id}"
    path_params: [{name: time_entry_id, var: time_entry_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_id: $time_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List possible time entry intervals
#
# GET /time_entry_intervals
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-intervals" [
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
    path: "/time_entry_intervals"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry interval
#
# GET /time_entry_intervals/{time_entry_interval_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool>
export def "get-time-entry-intervals-time-entry-interval-id" [
  time_entry_interval_id: string
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
    path: "/time_entry_intervals/{time_entry_interval_id}"
    path_params: [{name: time_entry_interval_id, var: time_entry_interval_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_interval_id: $time_entry_interval_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List time entry rates
#
# GET /time_entry_rates
# Returns: record<data: table<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-rates" [
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
    path: "/time_entry_rates"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new time entry rate
#
# POST /time_entry_rates
# Returns: record<data: record<id: string>, success: bool>
export def "post-time-entry-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-time: string # format: dateTime
  --is-all-day: oneof<nothing, bool>
  --project-id: string # format: uuid
  --sum: int # Amount of seconds - should only be included when using is_all_day, otherwise will be calculated from from_time and to_time (format: int32)
  time_entry_type_id: string # format: uuid
  --to-time: string # format: dateTime
  user_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/time_entry_rates"
    body: {content_type: "application/json", kind: json, fields: [{name: form_id, var: form_id}, {name: from_time, var: from_time}, {name: is_all_day, var: is_all_day}, {name: project_id, var: project_id}, {name: sum, var: sum}, {name: time_entry_type_id, var: time_entry_type_id}, {name: to_time, var: to_time}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    form_id: $form_id, from_time: $from_time, is_all_day: $is_all_day, project_id: $project_id, sum: $sum, time_entry_type_id: $time_entry_type_id, to_time: $to_time, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete time entry rate
#
# DELETE /time_entry_rates/{time_entry_rate_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-time-entry-rates-time-entry-rate-id" [
  time_entry_rate_id: string
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
    path: "/time_entry_rates/{time_entry_rate_id}"
    path_params: [{name: time_entry_rate_id, var: time_entry_rate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_rate_id: $time_entry_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry rate
#
# GET /time_entry_rates/{time_entry_rate_id}
# Returns: record<data: record<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, success: bool>
export def "get-time-entry-rates-time-entry-rate-id" [
  time_entry_rate_id: string
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
    path: "/time_entry_rates/{time_entry_rate_id}"
    path_params: [{name: time_entry_rate_id, var: time_entry_rate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_rate_id: $time_entry_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit time entry rate
#
# PUT /time_entry_rates/{time_entry_rate_id}
# Returns: record<data: list<record>, success: bool>
export def "put-time-entry-rates-time-entry-rate-id" [
  time_entry_rate_id: string
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
    path: "/time_entry_rates/{time_entry_rate_id}"
    path_params: [{name: time_entry_rate_id, var: time_entry_rate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_rate_id: $time_entry_rate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List time entry rule groups
#
# GET /time_entry_rule_groups
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, name: string, salary_period_days: float, salary_period_from: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-rule-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/time_entry_rule_groups"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List time entries types
#
# GET /time_entry_types
# Returns: record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-types" [
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
    path: "/time_entry_types"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new time entry type
#
# POST /time_entry_types
# Returns: record<data: record<id: string>, success: bool>
export def "post-time-entry-types" [
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
  name: string
  time_entry_interval_id: string # format: uuid
  time_entry_value_type_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/time_entry_types"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: time_entry_interval_id, var: time_entry_interval_id}, {name: time_entry_value_type_id, var: time_entry_value_type_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    description: $description, name: $name, time_entry_interval_id: $time_entry_interval_id, time_entry_value_type_id: $time_entry_value_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk activate time entry types
#
# POST /time_entry_types/bulkActivate
# Returns: record<data: list<string>, success: bool>
# operationId: bulkActivateTimeEntryTypes
export def "bulk-activate-time-entry-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/time_entry_types/bulkActivate"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk deactivate time entry types
#
# POST /time_entry_types/bulkDeactivate
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeactivateTimeEntryTypes
export def "bulk-deactivate-time-entry-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/time_entry_types/bulkDeactivate"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk delete time entry types
#
# DELETE /time_entry_types/bulkDelete
# Returns: record<data: list<string>, success: bool>
# operationId: bulkDeleteTimeEntryTypes
export def "bulk-delete-time-entry-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/time_entry_types/bulkDelete"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete time entry type
#
# DELETE /time_entry_types/{time_entry_type_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-time-entry-types-time-entry-type-id" [
  time_entry_type_id: string
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
    path: "/time_entry_types/{time_entry_type_id}"
    path_params: [{name: time_entry_type_id, var: time_entry_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_type_id: $time_entry_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry type
#
# GET /time_entry_types/{time_entry_type_id}
# Returns: record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, success: bool>
export def "get-time-entry-types-time-entry-type-id" [
  time_entry_type_id: string
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
    path: "/time_entry_types/{time_entry_type_id}"
    path_params: [{name: time_entry_type_id, var: time_entry_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_type_id: $time_entry_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit time entry type
#
# PUT /time_entry_types/{time_entry_type_id}
# Returns: record<data: list<record>, success: bool>
export def "put-time-entry-types-time-entry-type-id" [
  time_entry_type_id: string
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
    path: "/time_entry_types/{time_entry_type_id}"
    path_params: [{name: time_entry_type_id, var: time_entry_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_type_id: $time_entry_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List possible time entry unit types
#
# GET /time_entry_unit_types
# Returns: record<data: table<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-unit-types" [
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
    path: "/time_entry_unit_types"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry unit type
#
# GET /time_entry_unit_types/{time_entry_unit_type_id}
# Returns: record<data: record<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool>
export def "get-time-entry-unit-types-time-entry-unit-type-id" [
  time_entry_unit_type_id: string
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
    path: "/time_entry_unit_types/{time_entry_unit_type_id}"
    path_params: [{name: time_entry_unit_type_id, var: time_entry_unit_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_unit_type_id: $time_entry_unit_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List possible time entry value types
#
# GET /time_entry_value_types
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-time-entry-value-types" [
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
    path: "/time_entry_value_types"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View time entry value type
#
# GET /time_entry_value_types/{time_entry_value_type_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, success: bool>
export def "get-time-entry-value-types-time-entry-value-type-id" [
  time_entry_value_type_id: string
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
    path: "/time_entry_value_types/{time_entry_value_type_id}"
    path_params: [{name: time_entry_value_type_id, var: time_entry_value_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    time_entry_value_type_id: $time_entry_value_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user custom field attributes
#
# GET /user_custom_field_attributes
# Returns: record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-user-custom-field-attributes" [
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
    path: "/user_custom_field_attributes"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of 1 user custom field attribute
#
# GET /user_custom_field_attributes/{user_custom_field_attribute_id}
# Returns: record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool>
export def "get-user-custom-field-attributes-user-custom-field-attribute-id" [
  user_custom_field_attribute_id: string
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
    path: "/user_custom_field_attributes/{user_custom_field_attribute_id}"
    path_params: [{name: user_custom_field_attribute_id, var: user_custom_field_attribute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_custom_field_attribute_id: $user_custom_field_attribute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of users in company
#
# GET /users
# Returns: record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
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
  --first-name: string # Used to filter on the `first_name` of the users
  --last-name: string # Used to filter on the `last_name` of the users
  --email: string # Used to filter on the `email` of the users
  --stock-location-id: string # Used to filter on the `stock_location_id` of the users
  --is-active: oneof<nothing, bool> # Filters active/inactive users
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: email, var: email}, {name: stock_location_id, var: stock_location_id}, {name: is_active, var: is_active}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    first_name: $first_name, last_name: $last_name, email: $email, stock_location_id: $stock_location_id, is_active: $is_active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add user to company
#
# POST /users
# Returns: record<data: record<id: string>, success: bool>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city-id: string # format: uuid
  --cost-price: float # Cost of salaries (format: float)
  --email: string # format: email
  --expected-billable-hours: float # format: float
  --extra-price: float # Additional cost on this employee (pension, vacation etc.) (format: float)
  first_name: string
  --hide-address: oneof<nothing, bool>
  --hide-phone: oneof<nothing, bool>
  --initials: string
  --is-active: oneof<nothing, bool>
  --language-id: string # format: uuid
  --last-name: string
  --mobile: string
  --mobile-countrycode: string
  --password: string # format: password
  --phone: string
  --phone-countrycode: string
  --receive-form-mails: oneof<nothing, bool> # If `true` the employee will receive an email receipt of every form submitted
  --roles: record # shape: {_ids?: list<string>}
  --sale-price: float # The price this employee costs per hour when working (format: float)
  --street-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: city_id, var: city_id}, {name: cost_price, var: cost_price}, {name: email, var: email}, {name: expected_billable_hours, var: expected_billable_hours}, {name: extra_price, var: extra_price}, {name: first_name, var: first_name}, {name: hide_address, var: hide_address}, {name: hide_phone, var: hide_phone}, {name: initials, var: initials}, {name: is_active, var: is_active}, {name: language_id, var: language_id}, {name: last_name, var: last_name}, {name: mobile, var: mobile}, {name: mobile_countrycode, var: mobile_countrycode}, {name: password, var: password}, {name: phone, var: phone}, {name: phone_countrycode, var: phone_countrycode}, {name: receive_form_mails, var: receive_form_mails}, {name: roles, var: roles}, {name: sale_price, var: sale_price}, {name: street_name, var: street_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    city_id: $city_id, cost_price: $cost_price, email: $email, expected_billable_hours: $expected_billable_hours, extra_price: $extra_price, first_name: $first_name, hide_address: $hide_address, hide_phone: $hide_phone, initials: $initials, is_active: $is_active, language_id: $language_id, last_name: $last_name, mobile: $mobile, mobile_countrycode: $mobile_countrycode, password: $password, phone: $phone, phone_countrycode: $phone_countrycode, receive_form_mails: $receive_form_mails, roles: $roles, sale_price: $sale_price, street_name: $street_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate multiple users
#
# POST /users/bulkActivate
# Returns: record<data: list<string>, success: bool>
# operationId: usersBulkActivate
export def "users-bulk-activate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/bulkActivate"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate multiple users
#
# POST /users/bulkDeactivate
# Returns: record<data: list<string>, success: bool>
# operationId: usersBulkDeactivate
export def "users-bulk-deactivate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/bulkDeactivate"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Welcome SMS to the user
#
# GET /users/resendWelcomeSms
# Returns: record<data: record<message: string>, status: string>
export def "get-users-resend-welcome-sms" [
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
    path: "/users/resendWelcomeSms"
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /users/{user_id}
# Returns: record<data: list<record>, success: bool>
export def "delete-users-user-id" [
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View user
#
# GET /users/{user_id}
# Returns: record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool>
export def "get-users-user-id" [
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit user
#
# PUT /users/{user_id}
# Returns: record<data: list<record>, success: bool>
export def "put-users-user-id" [
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
    method: put
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user integration settings
#
# GET /users/{user_id}/integration_settings
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-users-user-id-integration-settings" [
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
    path: "/users/{user_id}/integration_settings"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user integration setting
#
# POST /users/{user_id}/integration_settings
# Returns: record<data: record<id: string>, success: bool>
export def "post-users-user-id-integration-settings" [
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
  --integration-setting-id: string # format: uuid
  --value: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/integration_settings"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: integration_setting_id, var: integration_setting_id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, integration_setting_id: $integration_setting_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user integration setting
#
# DELETE /users/{user_id}/integration_settings/{integration_settings_user_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-users-user-id-integration-settings-integration-settings-user-id" [
  user_id: string
  integration_settings_user_id: string
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
    path: "/users/{user_id}/integration_settings/{integration_settings_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: integration_settings_user_id, var: integration_settings_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, integration_settings_user_id: $integration_settings_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user integration setting
#
# GET /users/{user_id}/integration_settings/{integration_settings_user_id}
# Returns: record<data: record<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, success: bool>
export def "get-users-user-id-integration-settings-integration-settings-user-id" [
  user_id: string
  integration_settings_user_id: string
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
    path: "/users/{user_id}/integration_settings/{integration_settings_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: integration_settings_user_id, var: integration_settings_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, integration_settings_user_id: $integration_settings_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a user integration setting
#
# PUT /users/{user_id}/integration_settings/{integration_settings_user_id}
# Returns: record<data: list<string>, success: bool>
export def "put-users-user-id-integration-settings-integration-settings-user-id" [
  user_id: string
  integration_settings_user_id: string
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
    path: "/users/{user_id}/integration_settings/{integration_settings_user_id}"
    path_params: [{name: user_id, var: user_id}, {name: integration_settings_user_id, var: integration_settings_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, integration_settings_user_id: $integration_settings_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new image to a user
#
# POST /users/{user_id}/uploadImage
# Returns: record<data: record<id: string>, success: bool>
export def "post-users-user-id-upload-image" [
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
  --image: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/uploadImage"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: image, var: image}], files: [image]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user custom field values
#
# GET /users/{user_id}/user_custom_field_value
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-users-user-id-user-custom-field-value" [
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
    path: "/users/{user_id}/user_custom_field_value"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single record of user custom field value
#
# GET /users/{user_id}/user_custom_field_value/{user_custom_field_value_id}
# Returns: record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, success: bool>
export def "get-users-user-id-user-custom-field-value-user-custom-field-value-id" [
  user_id: string
  user_custom_field_value_id: string
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
    path: "/users/{user_id}/user_custom_field_value/{user_custom_field_value_id}"
    path_params: [{name: user_id, var: user_id}, {name: user_custom_field_value_id, var: user_custom_field_value_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, user_custom_field_value_id: $user_custom_field_value_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single record of user custom field value
#
# PUT /users/{user_id}/user_custom_field_value/{user_custom_field_value_id}
# Returns: record<data: list<any>, success: bool>
export def "put-users-user-id-user-custom-field-value-user-custom-field-value-id" [
  user_id: string
  user_custom_field_value_id: string
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
    path: "/users/{user_id}/user_custom_field_value/{user_custom_field_value_id}"
    path_params: [{name: user_id, var: user_id}, {name: user_custom_field_value_id, var: user_custom_field_value_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    user_id: $user_id, user_custom_field_value_id: $user_custom_field_value_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of price files
#
# GET /vendor_product_price_files
# Returns: record<data: table<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-vendor-product-price-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-name: string
  --vendor-name: string
  --vendor-ids: list<string>
  --status: string@status-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/vendor_product_price_files"
    query: [{name: file_name, var: file_name}, {name: vendor_name, var: vendor_name}, {name: vendor_ids, var: vendor_ids, style: csv}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    file_name: $file_name, vendor_name: $vendor_name, vendor_ids: $vendor_ids, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a vendor price file
#
# POST /vendor_product_price_files
# Returns: record<data: record<id: string>, success: bool>
export def "post-vendor-product-price-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  companies_vendor_id: string
  file: string # format: binary
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vendor_product_price_files"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companies_vendor_id, var: companies_vendor_id}, {name: file, var: file}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    companies_vendor_id: $companies_vendor_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single price file
#
# GET /vendor_product_price_files/{vendor_product_price_file_id}
# Returns: record<data: record<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int, download_link: string>, success: bool>
export def "get-vendor-product-price-files-vendor-product-price-file-id" [
  vendor_product_price_file_id: string
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
    path: "/vendor_product_price_files/{vendor_product_price_file_id}"
    path_params: [{name: vendor_product_price_file_id, var: vendor_product_price_file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    vendor_product_price_file_id: $vendor_product_price_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List vendor products
#
# GET /vendor_products
# Returns: record<data: table<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-vendor-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the vendor products
  --product-number: string # Used to filter on the `product_number` of the vendor products (format: uuid)
  --barcode: string # Used to filter on the `barcode` of the vendor products
  --vendor-id: string # Used to filter on the `vendor_id` of the vendor products
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/vendor_products"
    query: [{name: name, var: name}, {name: product_number, var: product_number}, {name: barcode, var: barcode}, {name: vendor_id, var: vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    name: $name, product_number: $product_number, barcode: $barcode, vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View single vendor product
#
# GET /vendor_products/{vendor_product_id}
# Returns: record<data: record<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, success: bool>
export def "get-vendor-products-vendor-product-id" [
  vendor_product_id: string
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
    path: "/vendor_products/{vendor_product_id}"
    path_params: [{name: vendor_product_id, var: vendor_product_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    vendor_product_id: $vendor_product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of vendors
#
# GET /vendors
# Returns: record<data: table<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
# operationId: getVendorsList
export def "get-vendors-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-custom: oneof<nothing, bool>
  --email: string
  --name: string
  --cvr: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/vendors"
    query: [{name: with_custom, var: with_custom}, {name: email, var: email}, {name: name, var: name}, {name: cvr, var: cvr}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    with_custom: $with_custom, email: $email, name: $name, cvr: $cvr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new vendor
#
# POST /vendors
# Returns: record<data: record<id: string>, success: bool>
# operationId: addVendor
export def "add-vendor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # format: uuid
  --cvr: string
  --email: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vendors"
    body: {content_type: "application/json", kind: json, fields: [{name: country_id, var: country_id}, {name: cvr, var: cvr}, {name: email, var: email}, {name: identifier, var: identifier}, {name: is_custom, var: is_custom}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    country_id: $country_id, cvr: $cvr, email: $email, identifier: $identifier, is_custom: $is_custom, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a vendor
#
# DELETE /vendors/{vendor_id}
# Returns: record<data: list<string>, success: bool>
export def "delete-vendors-vendor-id" [
  vendor_id: string
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
    path: "/vendors/{vendor_id}"
    path_params: [{name: vendor_id, var: vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a vendor
#
# GET /vendors/{vendor_id}
# Returns: record<data: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool>
# operationId: getVendor
export def "get-vendor" [
  vendor_id: string
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
    path: "/vendors/{vendor_id}"
    path_params: [{name: vendor_id, var: vendor_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    vendor_id: $vendor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a vendor
#
# PUT /vendors/{vendor_id}
# Returns: record<data: list<record>, success: bool>
# operationId: editVendor
export def "edit-vendor" [
  vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # format: uuid
  --cvr: string
  --email: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/vendors/{vendor_id}"
    path_params: [{name: vendor_id, var: vendor_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: country_id, var: country_id}, {name: cvr, var: cvr}, {name: email, var: email}, {name: identifier, var: identifier}, {name: is_custom, var: is_custom}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    vendor_id: $vendor_id, country_id: $country_id, cvr: $cvr, email: $email, identifier: $identifier, is_custom: $is_custom, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download salary file
#
# GET /wages/downloadSalaryFile
export def "get-wages-download-salary-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --company-id: string # format: uuid
]: nothing -> any {
  http-request {
    method: get
    path: "/wages/downloadSalaryFile"
    query: [{name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: company_id, var: company_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    date_from: $date_from, date_to: $date_to, company_id: $company_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add wall comment
#
# POST /wall_comments
# Returns: record<data: record<id: string>, success: bool>
export def "post-wall-comments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
  wall_post_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wall_comments"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: wall_post_id, var: wall_post_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    message: $message, wall_post_id: $wall_post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View wall comment
#
# GET /wall_comments/{wall_comment_id}
# Returns: record<data: record<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, success: bool>
export def "get-wall-comments-wall-comment-id" [
  wall_comment_id: string
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
    path: "/wall_comments/{wall_comment_id}"
    path_params: [{name: wall_comment_id, var: wall_comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    wall_comment_id: $wall_comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View list of wall posts
#
# GET /wall_posts
# Returns: record<data: table<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-wall-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # format: uuid
  --user-id: string # format: uuid
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wall_posts"
    query: [{name: project_id, var: project_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    project_id: $project_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a wall post
#
# POST /wall_posts
# Returns: record<data: record<id: string>, success: bool>
export def "post-wall-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
  project_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wall_posts"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: project_id, var: project_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-auth-token
  } {
    message: $message, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View wall post
#
# GET /wall_posts/{wall_post_id}
# Returns: record<data: record<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, success: bool>
export def "get-wall-posts-wall-post-id" [
  wall_post_id: string
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
    path: "/wall_posts/{wall_post_id}"
    path_params: [{name: wall_post_id, var: wall_post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    wall_post_id: $wall_post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# See wall comments to a wall post
#
# GET /wall_posts/{wall_post_id}/wall_comments
# Returns: record<data: table<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool>
export def "get-wall-posts-wall-post-id-wall-comments" [
  wall_post_id: string
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
    path: "/wall_posts/{wall_post_id}/wall_comments"
    path_params: [{name: wall_post_id, var: wall_post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-auth-token
  } {
    wall_post_id: $wall_post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
