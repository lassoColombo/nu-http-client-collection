# Auto-generated client for Billbee API v1
# Source: https://api.apis.guru/v2/specs/billbee.io/v1/openapi.json
# Auth: --token flag or $env.BILLBEE_API_TOKEN

const CLIENT = {
  base_url: "https://app.billbee.io"
  token_env_var: "BILLBEE_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-billbee-api-key, in: header, header_name: X-Billbee-Api-Key, prefix: ""}
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

def base-url-completer [] { ["https://app.billbee.io"] }
def auth-scheme-completer [] { ["x-billbee-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def default-vat-mode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def accept-completer [] { ["application/json" "text/json"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def address-type-completer [] { ["1" "2"] }
def article-title-source-completer [] { ["0" "1" "2" "3"] }
def payment-method-completer [] { ["1" "100" "101" "102" "103" "104" "105" "106" "107" "108" "109" "110" "111" "112" "113" "114" "115" "116" "117" "118" "119" "120" "121" "122" "123" "124" "125" "126" "127" "128" "129" "130" "131" "132" "133" "134" "135" "136" "19" "2" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "3" "30" "31" "32" "33" "34" "35" "36" "37" "38" "39" "4" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "6" "60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72" "73" "74" "75" "76" "77" "78" "79" "80" "81" "82" "83" "84" "85" "86" "87" "88" "89" "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"] }
def state-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def vat-mode-completer [] { ["0" "1" "2" "3" "4" "5"] }
def new-state-id-completer [] { ["1" "10" "11" "12" "13" "14" "15" "16" "2" "3" "4" "5" "6" "7" "8" "9"] }
def send-mode-completer [] { ["0" "1" "2" "3" "4"] }
def search-mode-completer [] { ["0" "1" "2" "3" "4"] }
def shipping-carrier-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "2" "3" "4" "5" "6" "7" "8" "9"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    automatic-provisioning-create-account: "record"
    automatic-provisioning-terms-info: "record"
    cloud-storage-api-get-list: "record<Data: table<Id: int, Name: string, Type: string, UsedAsPrinter: bool>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-addresses-get-all: "record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    customer-addresses-create: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-addresses-get-one: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-addresses-update: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-get-all: "record<Data: table<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    customer-create: "record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-get-customer-address: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-patch-address: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-update-address: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-get-one: "record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-update: "record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-get-customer-addresses: "record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    customer-add-customer-address: "record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    customer-get-customer-orders: "record<Data: table<CanCreateAutoInvoice: bool, CreatedAt: string, ExternalId: string, HasInvoice: bool, Id: int, InvoiceCreatedAt: string, InvoiceDate: string, InvoiceNumber: string, OrderStateId: int, OrderStateText: string, PaidAt: string, ShippedAt: string, ShopName: string, TotalGross: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    enum-api-get-order-states: "record"
    enum-api-get-payment-types: "record"
    enum-api-get-shipment-types: "record"
    enum-api-get-shipping-carriers: "record"
    event-api-get-list: "record"
    layout-api-get-list: "record<Data: table<Id: int, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    order-api-get-list: "record<Data: table<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record, Comments: list, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list, Id: string, InvoiceAddress: record, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list, RebateDifference: float, RestoredAt: string, Seller: record, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record, ShippingCost: float, ShippingIds: list, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list, State: int, Tags: list, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    order-api-post-new-order: "record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    order-api-create-delivery-note: "record"
    order-api-create-invoice: "record"
    order-api-get-patchable-fields: "record"
    order-api-find: "record"
    order-api-get-by-ext-ref: "record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    order-api-get-invoice-list: "record"
    order-api-get: "record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    order-api-patch-order: "record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    order-api-update-state: "record"
    order-api-parse-placeholders: "record"
    order-api-send-message: "record"
    order-api-add-shipment: "record"
    order-api-tags-create: "record"
    order-api-tags-update: "record"
    order-api-trigger-event: "record"
    article-get-list: "record<Data: table<BasicAttributes: list, BillOfMaterial: list, Category1: record, Category2: record, Category3: record, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list, DeliveryTime: int, Description: list, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list, HeightCm: float, Id: int, Images: list, InvoiceText: list, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list, Tags: list, TaricNumber: string, Title: list, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    article-create-article: "record"
    article-get-patchable-fields: "record"
    article-get-category: "record"
    article-get-custom-fields: "record<Data: table<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    article-get-custom-field: "record<Data: record<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-delete-images: "record<Data: record<Deleted: list<int>, NotFound: list<int>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-delete-image: "record"
    article-get-image: "record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-get-reserved-amount: "record<Data: record<ReservedAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-get-stocks: "record<Data: table<Description: string, Id: int, IsDefault: bool, Name: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-update-stock: "record<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-update-stock-code: "record<Data: record, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-update-stock-multiple: "table<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-delete-article: "record"
    article-get-article: "record<Data: record<BasicAttributes: list<record>, BillOfMaterial: list<record>, Category1: record<Id: int, Name: string>, Category2: record<Id: int, Name: string>, Category3: record<Id: int, Name: string>, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list<record>, DeliveryTime: int, Description: list<record>, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list<record>, HeightCm: float, Id: int, Images: list<record>, InvoiceText: list<record>, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list<record>, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list<record>, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list<record>, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list<record>, Tags: list<record>, TaricNumber: string, Title: list<record>, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-patch-article: "record"
    article-get-images: "record<Data: table<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-put-images: "record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-delete-image-from-product: "record"
    article-get-image-from-product: "record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    article-put-image: "record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    search-search: "record<Data: record<Customers: list<record>, Orders: list<record>, Products: list<record>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    shipment-get-ping: "record"
    shipment-post-shipment: "record"
    shipment-get-list: "record<Data: table<BillbeeId: int, Created: string, ShipmentType: int, Shipper: string, ShippingCarrier: int, ShippingId: string, ShippingProviderId: int, ShippingProviderProductId: int, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>"
    shipment-get-shipping-carrier: "record"
    shipment-get-shippingproviders: "record"
    shipment-ship-with-label: "record<Data: record<Carrier: string, ExportDocsPdf: string, LabelDataPdf: string, OrderId: int, OrderReference: string, ShippingDate: string, ShippingId: string, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>"
    web-hook-management-delete-all: "record"
    web-hook-management-get: "table<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>"
    web-hook-management-post: "record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>"
    web-hook-management-get-filters: "record"
    web-hook-management-delete: "record"
    web-hook-management-lookup: "record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>"
    web-hook-management-put: "record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["automatic-provisioning-create-account" "automatic-provisioning-terms-info" "cloud-storage-api-get-list" "customer-addresses-get-all" "customer-addresses-create" "customer-addresses-get-one" "customer-addresses-update" "customer-get-all" "customer-create" "customer-get-customer-address" "customer-patch-address" "customer-update-address" "customer-get-one" "customer-update" "customer-get-customer-addresses" "customer-add-customer-address" "customer-get-customer-orders" "enum-api-get-order-states" "enum-api-get-payment-types" "enum-api-get-shipment-types" "enum-api-get-shipping-carriers" "event-api-get-list" "layout-api-get-list" "order-api-get-list" "order-api-post-new-order" "order-api-create-delivery-note" "order-api-create-invoice" "order-api-get-patchable-fields" "order-api-find" "order-api-get-by-ext-ref" "order-api-get-invoice-list" "order-api-get" "order-api-patch-order" "order-api-update-state" "order-api-parse-placeholders" "order-api-send-message" "order-api-add-shipment" "order-api-tags-create" "order-api-tags-update" "order-api-trigger-event" "article-get-list" "article-create-article" "article-get-patchable-fields" "article-get-category" "article-get-custom-fields" "article-get-custom-field" "article-delete-images" "article-delete-image" "article-get-image" "article-get-reserved-amount" "article-get-stocks" "article-update-stock" "article-update-stock-code" "article-update-stock-multiple" "article-delete-article" "article-get-article" "article-patch-article" "article-get-images" "article-put-images" "article-delete-image-from-product" "article-get-image-from-product" "article-put-image" "search-search" "shipment-get-ping" "shipment-post-shipment" "shipment-get-list" "shipment-get-shipping-carrier" "shipment-get-shippingproviders" "shipment-ship-with-label" "web-hook-management-delete-all" "web-hook-management-get" "web-hook-management-post" "web-hook-management-get-filters" "web-hook-management-delete" "web-hook-management-lookup" "web-hook-management-put" "commands"] | sort) } | get name | first)
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

# Creates a new Billbee user account with the data passed
#
# POST /api/v1/automaticprovision/createaccount
# Returns: record
# operationId: AutomaticProvisioning_CreateAccount
export def "automatic-provisioning-create-account" [
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
  --accept-terms: oneof<nothing, bool> # Set to true, if the user has accepted the Billbee terms & conditions
  --address: record # Represents the invoice address of a Billbee user — shape: {Address1?: string, Address2?: string, City?: string, Company?: string, Country?: string, Name?: string, VatId?: string, Zip?: string}
  --affiliate-coupon-code: string # Specifies an billbee affiliate code to attach to the user
  --default-currrency: string # Optionally specify the default currency of the user
  --default-vat-index: int # Optionally specify the default vat index of the user (format: int32)
  --default-vat-mode: int@default-vat-mode-completer # Optionally specify the default vat mode of the user (format: int32)
  e_mail: string # The Email address of the user to create
  --password: string
  --vat1-rate: float # Optionally specify the vat1 (normal) rate of the user (format: double)
  --vat2-rate: float # Optionally specify the vat2 (reduced) rate of the user (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/automaticprovision/createaccount"
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptTerms, var: accept_terms}, {name: Address, var: address}, {name: AffiliateCouponCode, var: affiliate_coupon_code}, {name: DefaultCurrrency, var: default_currrency}, {name: DefaultVatIndex, var: default_vat_index}, {name: DefaultVatMode, var: default_vat_mode}, {name: EMail, var: e_mail}, {name: Password, var: password}, {name: Vat1Rate, var: vat1_rate}, {name: Vat2Rate, var: vat2_rate}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    accept_terms: $accept_terms, address: $address, affiliate_coupon_code: $affiliate_coupon_code, default_currrency: $default_currrency, default_vat_index: $default_vat_index, default_vat_mode: $default_vat_mode, e_mail: $e_mail, password: $password, vat1_rate: $vat1_rate, vat2_rate: $vat2_rate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns infos about Billbee terms and conditions
#
# GET /api/v1/automaticprovision/termsinfo
# Returns: record
# operationId: AutomaticProvisioning_TermsInfo
export def "automatic-provisioning-terms-info" [
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
    path: "/api/v1/automaticprovision/termsinfo"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of all connected cloud storage devices
#
# GET /api/v1/cloudstorages
# Returns: record<Data: table<Id: int, Name: string, Type: string, UsedAsPrinter: bool>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: CloudStorageApi_GetList
export def "cloud-storage-api-get-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/cloudstorages"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all customer addresses
#
# GET /api/v1/customer-addresses
# Returns: record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: CustomerAddresses_GetAll
export def "customer-addresses-get-all" [
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
  --page: int # The current page to request starting with 1 (default is 1) (format: int32)
  --page-size: int # The page size for the result list. Values between 1 and 250 are allowed. (default is 50) (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customer-addresses"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new customer address
#
# POST /api/v1/customer-addresses
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: CustomerAddresses_Create
export def "customer-addresses-create" [
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
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/customer-addresses"
    body: {content_type: "application/json", kind: json, fields: [{name: AddressAddition, var: address_addition}, {name: AddressType, var: address_type}, {name: ArchivedAt, var: archived_at}, {name: City, var: city}, {name: Company, var: company}, {name: CountryCode, var: country_code}, {name: CustomerId, var: customer_id}, {name: Email, var: email}, {name: Fax, var: fax}, {name: FirstName, var: first_name}, {name: Housenumber, var: housenumber}, {name: Id, var: id}, {name: LastName, var: last_name}, {name: Name2, var: name2}, {name: RestoredAt, var: restored_at}, {name: State, var: state}, {name: Street, var: street}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Zip, var: zip}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    address_addition: $address_addition, address_type: $address_type, archived_at: $archived_at, city: $city, company: $company, country_code: $country_code, customer_id: $customer_id, email: $email, fax: $fax, first_name: $first_name, housenumber: $housenumber, id: $id, last_name: $last_name, name2: $name2, restored_at: $restored_at, state: $state, street: $street, tel1: $tel1, tel2: $tel2, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a single customer address by id
#
# GET /api/v1/customer-addresses/{id}
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: CustomerAddresses_GetOne
export def "customer-addresses-get-one" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customer-addresses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a customer address by id
#
# PUT /api/v1/customer-addresses/{id}
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: CustomerAddresses_Update
export def "customer-addresses-update" [
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
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64) (spec name: Id)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/customer-addresses/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddressAddition, var: address_addition}, {name: AddressType, var: address_type}, {name: ArchivedAt, var: archived_at}, {name: City, var: city}, {name: Company, var: company}, {name: CountryCode, var: country_code}, {name: CustomerId, var: customer_id}, {name: Email, var: email}, {name: Fax, var: fax}, {name: FirstName, var: first_name}, {name: Housenumber, var: housenumber}, {name: Id, var: body_id}, {name: LastName, var: last_name}, {name: Name2, var: name2}, {name: RestoredAt, var: restored_at}, {name: State, var: state}, {name: Street, var: street}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Zip, var: zip}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, address_addition: $address_addition, address_type: $address_type, archived_at: $archived_at, city: $city, company: $company, country_code: $country_code, customer_id: $customer_id, email: $email, fax: $fax, first_name: $first_name, housenumber: $housenumber, body_id: $body_id, last_name: $last_name, name2: $name2, restored_at: $restored_at, state: $state, street: $street, tel1: $tel1, tel2: $tel2, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all customers
#
# GET /api/v1/customers
# Returns: record<Data: table<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Customer_GetAll
export def "customer-get-all" [
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
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customers"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new customer
#
# POST /api/v1/customers
# Returns: record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_Create
export def "customer-create" [
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
  --address: record # Container for passing address data — shape: {AddressAddition?: string, AddressType?: "1"|"2", ArchivedAt?: string, City?: string, Company?: string, CountryCode?: string, CustomerId?: int, Email?: string, Fax?: string, FirstName?: string, Housenumber?: string, Id?: int, LastName?: string, Name2?: string, RestoredAt?: string, State?: string, Street?: string, Tel1?: string, Tel2?: string, Zip?: string}
  --archived-at: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --default-commercial-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-fax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-status-updates-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --email: string
  --id: int # The Billbee Id of the customer (format: int64)
  --language-id: int # format: int32
  --meta-data: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --name: string
  --number: int # format: int32
  --price-group-id: int # format: int64
  --restored-at: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --tel1: string
  --tel2: string
  --type: int # Customer Type (format: int32)
  --vat-id: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/customers"
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}, {name: ArchivedAt, var: archived_at}, {name: DefaultCommercialMailAddress, var: default_commercial_mail_address}, {name: DefaultFax, var: default_fax}, {name: DefaultMailAddress, var: default_mail_address}, {name: DefaultPhone1, var: default_phone1}, {name: DefaultPhone2, var: default_phone2}, {name: DefaultStatusUpdatesMailAddress, var: default_status_updates_mail_address}, {name: Email, var: email}, {name: Id, var: id}, {name: LanguageId, var: language_id}, {name: MetaData, var: meta_data}, {name: Name, var: name}, {name: Number, var: number}, {name: PriceGroupId, var: price_group_id}, {name: RestoredAt, var: restored_at}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Type, var: type}, {name: VatId, var: vat_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    address: $address, archived_at: $archived_at, default_commercial_mail_address: $default_commercial_mail_address, default_fax: $default_fax, default_mail_address: $default_mail_address, default_phone1: $default_phone1, default_phone2: $default_phone2, default_status_updates_mail_address: $default_status_updates_mail_address, email: $email, id: $id, language_id: $language_id, meta_data: $meta_data, name: $name, number: $number, price_group_id: $price_group_id, restored_at: $restored_at, tel1: $tel1, tel2: $tel2, type: $type, vat_id: $vat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a single address from a customer
#
# GET /api/v1/customers/addresses/{id}
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_GetCustomerAddress
export def "customer-get-customer-address" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customers/addresses/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates one or more fields of an address
#
# PATCH /api/v1/customers/addresses/{id}
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_PatchAddress
export def "customer-patch-address" [
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
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/customers/addresses/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates all fields of an address
#
# PUT /api/v1/customers/addresses/{id}
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_UpdateAddress
export def "customer-update-address" [
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
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64) (spec name: Id)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/customers/addresses/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddressAddition, var: address_addition}, {name: AddressType, var: address_type}, {name: ArchivedAt, var: archived_at}, {name: City, var: city}, {name: Company, var: company}, {name: CountryCode, var: country_code}, {name: CustomerId, var: customer_id}, {name: Email, var: email}, {name: Fax, var: fax}, {name: FirstName, var: first_name}, {name: Housenumber, var: housenumber}, {name: Id, var: body_id}, {name: LastName, var: last_name}, {name: Name2, var: name2}, {name: RestoredAt, var: restored_at}, {name: State, var: state}, {name: Street, var: street}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Zip, var: zip}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, address_addition: $address_addition, address_type: $address_type, archived_at: $archived_at, city: $city, company: $company, country_code: $country_code, customer_id: $customer_id, email: $email, fax: $fax, first_name: $first_name, housenumber: $housenumber, body_id: $body_id, last_name: $last_name, name2: $name2, restored_at: $restored_at, state: $state, street: $street, tel1: $tel1, tel2: $tel2, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a single customer by id
#
# GET /api/v1/customers/{id}
# Returns: record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_GetOne
export def "customer-get-one" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a customer by id
#
# PUT /api/v1/customers/{id}
# Returns: record<Data: record<ArchivedAt: string, DefaultCommercialMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultFax: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone1: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultPhone2: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, DefaultStatusUpdatesMailAddress: record<Id: int, SubType: string, TypeId: int, TypeName: string, Value: string>, Email: string, Id: int, LanguageId: int, MetaData: list<record>, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_Update
export def "customer-update" [
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
  --accept: string@accept-completer-1 # Response content type
  --archived-at: string # If set, the customer was already archived at the given date. Further modification is disabled. (format: date-time)
  --default-commercial-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-fax: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone1: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-phone2: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --default-status-updates-mail-address: record # shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --email: string
  --body-id: int # The Billbee Id of the customer (format: int64) (spec name: Id)
  --language-id: int # format: int32
  --meta-data: list # item shape: {Id?: int, SubType?: string, TypeId?: int, Value?: string}
  --name: string
  --number: int # format: int32
  --price-group-id: int # format: int64
  --restored-at: string # If set, the customer was restored from the archive at the given date. (format: date-time)
  --tel1: string
  --tel2: string
  --type: int # Customer Type (format: int32)
  --vat-id: string # The vat-id, that should be saved at the customer. Only used if CustomerVatId is not set on the order.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/customers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArchivedAt, var: archived_at}, {name: DefaultCommercialMailAddress, var: default_commercial_mail_address}, {name: DefaultFax, var: default_fax}, {name: DefaultMailAddress, var: default_mail_address}, {name: DefaultPhone1, var: default_phone1}, {name: DefaultPhone2, var: default_phone2}, {name: DefaultStatusUpdatesMailAddress, var: default_status_updates_mail_address}, {name: Email, var: email}, {name: Id, var: body_id}, {name: LanguageId, var: language_id}, {name: MetaData, var: meta_data}, {name: Name, var: name}, {name: Number, var: number}, {name: PriceGroupId, var: price_group_id}, {name: RestoredAt, var: restored_at}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Type, var: type}, {name: VatId, var: vat_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, archived_at: $archived_at, default_commercial_mail_address: $default_commercial_mail_address, default_fax: $default_fax, default_mail_address: $default_mail_address, default_phone1: $default_phone1, default_phone2: $default_phone2, default_status_updates_mail_address: $default_status_updates_mail_address, email: $email, body_id: $body_id, language_id: $language_id, meta_data: $meta_data, name: $name, number: $number, price_group_id: $price_group_id, restored_at: $restored_at, tel1: $tel1, tel2: $tel2, type: $type, vat_id: $vat_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a list of addresses from a customer
#
# GET /api/v1/customers/{id}/addresses
# Returns: record<Data: table<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Customer_GetCustomerAddresses
export def "customer-get-customer-addresses" [
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
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customers/{id}/addresses"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a new address to a customer
#
# POST /api/v1/customers/{id}/addresses
# Returns: record<Data: record<AddressAddition: string, AddressType: int, ArchivedAt: string, City: string, Company: string, CountryCode: string, CustomerId: int, Email: string, Fax: string, FirstName: string, Housenumber: string, Id: int, LastName: string, Name2: string, RestoredAt: string, State: string, Street: string, Tel1: string, Tel2: string, Zip: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Customer_AddCustomerAddress
export def "customer-add-customer-address" [
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
  --accept: string@accept-completer-1 # Response content type
  --address-addition: string
  --address-type: int@address-type-completer # The type of the address (format: int32)
  --archived-at: string # If set, the customeraddress was already archived at the given date. Further modification is disabled. (format: date-time)
  --city: string
  --company: string # The name of the company
  --country-code: string # The ISO2 code of the country
  --customer-id: int # The internal Billbee id of the customer the address belongs to (format: int64)
  --email: string
  --fax: string
  --first-name: string
  --housenumber: string
  --body-id: int # The internal Billbee ID of the address record. Can be null if a new address is created (format: int64) (spec name: Id)
  --last-name: string
  --name2: string # Optionally an additional name field
  --restored-at: string # If set, the customeraddress was restored from the archive at the given date. (format: date-time)
  --state: string
  --street: string
  --tel1: string
  --tel2: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/customers/{id}/addresses"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddressAddition, var: address_addition}, {name: AddressType, var: address_type}, {name: ArchivedAt, var: archived_at}, {name: City, var: city}, {name: Company, var: company}, {name: CountryCode, var: country_code}, {name: CustomerId, var: customer_id}, {name: Email, var: email}, {name: Fax, var: fax}, {name: FirstName, var: first_name}, {name: Housenumber, var: housenumber}, {name: Id, var: body_id}, {name: LastName, var: last_name}, {name: Name2, var: name2}, {name: RestoredAt, var: restored_at}, {name: State, var: state}, {name: Street, var: street}, {name: Tel1, var: tel1}, {name: Tel2, var: tel2}, {name: Zip, var: zip}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, address_addition: $address_addition, address_type: $address_type, archived_at: $archived_at, city: $city, company: $company, country_code: $country_code, customer_id: $customer_id, email: $email, fax: $fax, first_name: $first_name, housenumber: $housenumber, body_id: $body_id, last_name: $last_name, name2: $name2, restored_at: $restored_at, state: $state, street: $street, tel1: $tel1, tel2: $tel2, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a list of orders from a customer
#
# GET /api/v1/customers/{id}/orders
# Returns: record<Data: table<CanCreateAutoInvoice: bool, CreatedAt: string, ExternalId: string, HasInvoice: bool, Id: int, InvoiceCreatedAt: string, InvoiceDate: string, InvoiceNumber: string, OrderStateId: int, OrderStateText: string, PaidAt: string, ShippedAt: string, ShopName: string, TotalGross: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Customer_GetCustomerOrders
export def "customer-get-customer-orders" [
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
  --accept: string@accept-completer-1 # Response content type
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/customers/{id}/orders"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list with all defined orderstates
#
# GET /api/v1/enums/orderstates
# Returns: record
# operationId: EnumApi_GetOrderStates
export def "enum-api-get-order-states" [
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
    path: "/api/v1/enums/orderstates"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list with all defined paymenttypes
#
# GET /api/v1/enums/paymenttypes
# Returns: record
# operationId: EnumApi_GetPaymentTypes
export def "enum-api-get-payment-types" [
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
    path: "/api/v1/enums/paymenttypes"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list with all defined shipmenttypes
#
# GET /api/v1/enums/shipmenttypes
# Returns: record
# operationId: EnumApi_GetShipmentTypes
export def "enum-api-get-shipment-types" [
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
    path: "/api/v1/enums/shipmenttypes"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list with all defined shippingcarriers
#
# GET /api/v1/enums/shippingcarriers
# Returns: record
# operationId: EnumApi_GetShippingCarriers
export def "enum-api-get-shipping-carriers" [
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
    path: "/api/v1/enums/shippingcarriers"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all events optionally filtered by date. This request is extra throttled to 2 calls per page per hour.
#
# GET /api/v1/events
# Returns: record
# operationId: EventApi_GetList
export def "event-api-get-list" [
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
  --min-date: string # Specifies the oldest date to include in the response (format: date-time)
  --max-date: string # Specifies the newest date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --type-id: list<int> # Filter for specific event types
  --order-id: int # Filter for specific order id (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/events"
    query: [{name: minDate, var: min_date}, {name: maxDate, var: max_date}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: typeId, var: type_id, style: multi}, {name: orderId, var: order_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    min_date: $min_date, max_date: $max_date, page: $page, page_size: $page_size, type_id: $type_id, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/layouts
#
# Returns: record<Data: table<Id: int, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: LayoutApi_GetList
export def "layout-api-get-list" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/layouts"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all orders optionally filtered by date
#
# GET /api/v1/orders
# Returns: record<Data: table<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record, Comments: list, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list, Id: string, InvoiceAddress: record, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list, RebateDifference: float, RestoredAt: string, Seller: record, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record, ShippingCost: float, ShippingIds: list, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list, State: int, Tags: list, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: OrderApi_GetList
export def "order-api-get-list" [
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
  --min-order-date: string # Specifies the oldest order date to include in the response (format: date-time)
  --max-order-date: string # Specifies the newest order date to include in the response (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shop-id: list<int> # Specifies a list of shop ids for which invoices should be included
  --order-state-id: list<int> # Specifies a list of state ids to include in the response
  --tag: list<string> # Specifies a list of tags the order must have attached to be included in the response
  --minimum-bill-bee-order-id: int # If given, all delivered orders have an Id greater than or equal to the given minimumOrderId (format: int64)
  --modified-at-min: string # If given, the last modification has to be newer than the given date (format: date-time)
  --modified-at-max: string # If given, the last modification has to be older or equal than the given date. (format: date-time)
  --article-title-source: int@article-title-source-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
  --exclude-tags: oneof<nothing, bool> # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/orders"
    query: [{name: minOrderDate, var: min_order_date}, {name: maxOrderDate, var: max_order_date}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: shopId, var: shop_id, style: multi}, {name: orderStateId, var: order_state_id, style: multi}, {name: tag, var: tag, style: multi}, {name: minimumBillBeeOrderId, var: minimum_bill_bee_order_id}, {name: modifiedAtMin, var: modified_at_min}, {name: modifiedAtMax, var: modified_at_max}, {name: articleTitleSource, var: article_title_source}, {name: excludeTags, var: exclude_tags}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    min_order_date: $min_order_date, max_order_date: $max_order_date, page: $page, page_size: $page_size, shop_id: $shop_id, order_state_id: $order_state_id, tag: $tag, minimum_bill_bee_order_id: $minimum_bill_bee_order_id, modified_at_min: $modified_at_min, modified_at_max: $modified_at_max, article_title_source: $article_title_source, exclude_tags: $exclude_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new order in the Billbee account
#
# POST /api/v1/orders
# Returns: record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: OrderApi_PostNewOrder
export def "order-api-post-new-order" [
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
  --shop-id: int # Deprecated, if orderData.ApiAccountId is set, it will be used instead of 'shopId' (format: int64)
  --accept-loss-of-return-right: oneof<nothing, bool> # Customer accepts loss due to withdrawal
  --adjustment-cost: float # format: double
  --adjustment-reason: string
  --api-account-id: int # Id of the account, this order belongs to (format: int64)
  --api-account-name: string # The name of the account, this order belongs to. Will be ignored on order creation.
  --archived-at: string # If set, the order was already archived at the given date. Further modification is disabled. (format: date-time)
  --bill-bee-order-id: int # The Order.Id from the Billbee database (format: int64)
  --bill-bee-parent-order-id: int # The Id of the parent order in the Billbee database (format: int64)
  --buyer: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --comments: list # All messages / comments of the order — item shape: {Created?: string, FromCustomer?: bool, Id?: int, Name?: string, Text?: string}
  --confirmed-at: string # The date on which the order was confirmed (format: date-time)
  --created-at: string # The date on which the order was created (format: date-time)
  --currency: string # The three letter currency code.
  --custom-invoice-note: string # An optional multiline text which is printed on the invoice
  --customer: record # shape: {ArchivedAt?: string, DefaultCommercialMailAddress?: record, DefaultFax?: record, DefaultMailAddress?: record, DefaultPhone1?: record, DefaultPhone2?: record, DefaultStatusUpdatesMailAddress?: record, Email?: string, Id?: int, LanguageId?: int, MetaData?: list, Name?: string, Number?: int, PriceGroupId?: int, RestoredAt?: string, Tel1?: string, Tel2?: string, Type?: int, VatId?: string}
  --customer-number: string # The customer number (not to be confused with the id of the customer)
  --customer-vat-id: string # The vat-id, that was given by the customer to fulfill this order
  --delivery-source-country-code: string # An optional Country ISO2 Code of the country where order is shipped from (FBA)
  --distribution-center: string # An optional code for the distribution center delivering this order
  --history: list # item shape: {Created?: string, EmployeeName?: string, EventTypeName?: string, Text?: string, TypeId?: int}
  --id: string # Id of the order in the external system (marketplace)
  --invoice-address: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --invoice-date: string # The date on which the invoice was created (format: date-time)
  --invoice-number: int # The invoice number (format: int32)
  --invoice-number-postfix: string # The postfix of the invoice number
  --invoice-number-prefix: string # The prefix of the invoice number
  --is-cancelation-for: string # An optional Order Id (externalid) for an order if this is a cancel order (shopify only at the moment)
  --is-from-billbee-api: oneof<nothing, bool> # Indicates whether the order was created through the Billbee-Api or not.
  --language-code: string # The two-letter language code of the customer
  --last-modified-at: string # Date of the last update, the order got (format: date-time)
  --merchant-vat-id: string # The vat-id, that should be displayed on the invoice and other order documents
  --order-items: list # The list of items purchased like shirt, pant, toys etc — item shape: {Attributes?: list, BillbeeId?: int, Discount?: float, DontAdjustStock?: bool, GetPriceFromArticleIfAny?: bool, InvoiceSKU?: string, IsCoupon?: bool, Product?: record, Quantity?: float, SerialNumber?: string, ShippingProfileId?: string, TaxAmount?: float, TaxIndex?: int, TotalPrice?: float, TransactionId?: string, UnrebatedTotalPrice?: float}
  --order-number: string # Order number of the order in the external system (marketplace)
  --paid-amount: float # format: double
  --payed-at: string # The date on which the order was paid (format: date-time)
  --payment-instruction: string # A textfield optionaly filled with a payment instruction text for printout on the invoice (z.B. Ebay Kauf auf Rechnung)
  --payment-method: int@payment-method-completer # The payment method (format: int32)
  --payment-reference: string # A payment reference. Should not be used any more. Please use 'Payments' instead.
  --payment-transaction-id: string # The id of the payment transaction. For example the transaction id of PayPal payment. Should not be used any more. Please use 'Payments' instead.
  --payments: list # item shape: {BillbeeId?: int, Name?: string, PayDate?: string, PayValue?: float, PaymentType?: int, Purpose?: string, SourceTechnology?: string, SourceText?: string, TransactionId?: string}
  --restored-at: string # If set, the order was restored from the archive at the given date. (format: date-time)
  --seller: record # shape: {BillbeeShopId?: int, BillbeeShopName?: string, Email?: string, FirstName?: string, Id?: string, LastName?: string, Nick?: string, Platform?: string}
  --seller-comment: string # An internal seller comment
  --ship-weight-kg: float # The total weight of the shipment(s) (format: double)
  --shipped-at: string # The date on which the order was shipped (format: date-time)
  --shipping-address: record # shape: {BillbeeId?: int, City?: string, Company?: string, Country?: string, CountryISO2?: string, Email?: string, FirstName?: string, HouseNumber?: string, LastName?: string, Line2?: string, NameAddition?: string, Phone?: string, State?: string, Street?: string, Zip?: string}
  --shipping-cost: float # The shipping cost (format: double)
  --shipping-ids: list # The shipments of the order — item shape: {BillbeeId?: int, Created?: string, ShipmentType?: int, Shipper?: string, ShippingCarrier?: int, ShippingId?: string, ShippingProviderId?: int, ShippingProviderProductId?: int, TrackingUrl?: string}
  --shipping-profile-id: string # Internal Id for the shipping profile for that order
  --shipping-profile-name: string # Display Name of Shipping profile, if available
  --shipping-provider-id: int # Internal Id for the used shipping provider (format: int64)
  --shipping-provider-name: string # The Name for of used shipping provider
  --shipping-provider-product-id: int # Internal Id for the used shipping product (format: int64)
  --shipping-provider-product-name: string # The Name of the used shipping product
  --shipping-services: list # Additional services for the shipment
  --state: int@state-completer # The current state of the order (format: int32)
  --tags: list<string> # The Tags of the order
  --tax-rate1: float # The regular tax rate (format: double)
  --tax-rate2: float # The reduced tax rate (format: double)
  --total-cost: float # The total cost excluding shipping cost (format: double)
  --updated-at: string # The date on which the order was last updated (format: date-time)
  --vat-id: string # The customers vat id
  --vat-mode: int@vat-mode-completer # The vat mode of the order (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders"
    query: [{name: shopId, var: shop_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptLossOfReturnRight, var: accept_loss_of_return_right}, {name: AdjustmentCost, var: adjustment_cost}, {name: AdjustmentReason, var: adjustment_reason}, {name: ApiAccountId, var: api_account_id}, {name: ApiAccountName, var: api_account_name}, {name: ArchivedAt, var: archived_at}, {name: BillBeeOrderId, var: bill_bee_order_id}, {name: BillBeeParentOrderId, var: bill_bee_parent_order_id}, {name: Buyer, var: buyer}, {name: Comments, var: comments}, {name: ConfirmedAt, var: confirmed_at}, {name: CreatedAt, var: created_at}, {name: Currency, var: currency}, {name: CustomInvoiceNote, var: custom_invoice_note}, {name: Customer, var: customer}, {name: CustomerNumber, var: customer_number}, {name: CustomerVatId, var: customer_vat_id}, {name: DeliverySourceCountryCode, var: delivery_source_country_code}, {name: DistributionCenter, var: distribution_center}, {name: History, var: history}, {name: Id, var: id}, {name: InvoiceAddress, var: invoice_address}, {name: InvoiceDate, var: invoice_date}, {name: InvoiceNumber, var: invoice_number}, {name: InvoiceNumberPostfix, var: invoice_number_postfix}, {name: InvoiceNumberPrefix, var: invoice_number_prefix}, {name: IsCancelationFor, var: is_cancelation_for}, {name: IsFromBillbeeApi, var: is_from_billbee_api}, {name: LanguageCode, var: language_code}, {name: LastModifiedAt, var: last_modified_at}, {name: MerchantVatId, var: merchant_vat_id}, {name: OrderItems, var: order_items}, {name: OrderNumber, var: order_number}, {name: PaidAmount, var: paid_amount}, {name: PayedAt, var: payed_at}, {name: PaymentInstruction, var: payment_instruction}, {name: PaymentMethod, var: payment_method}, {name: PaymentReference, var: payment_reference}, {name: PaymentTransactionId, var: payment_transaction_id}, {name: Payments, var: payments}, {name: RestoredAt, var: restored_at}, {name: Seller, var: seller}, {name: SellerComment, var: seller_comment}, {name: ShipWeightKg, var: ship_weight_kg}, {name: ShippedAt, var: shipped_at}, {name: ShippingAddress, var: shipping_address}, {name: ShippingCost, var: shipping_cost}, {name: ShippingIds, var: shipping_ids}, {name: ShippingProfileId, var: shipping_profile_id}, {name: ShippingProfileName, var: shipping_profile_name}, {name: ShippingProviderId, var: shipping_provider_id}, {name: ShippingProviderName, var: shipping_provider_name}, {name: ShippingProviderProductId, var: shipping_provider_product_id}, {name: ShippingProviderProductName, var: shipping_provider_product_name}, {name: ShippingServices, var: shipping_services}, {name: State, var: state}, {name: Tags, var: tags}, {name: TaxRate1, var: tax_rate1}, {name: TaxRate2, var: tax_rate2}, {name: TotalCost, var: total_cost}, {name: UpdatedAt, var: updated_at}, {name: VatId, var: vat_id}, {name: VatMode, var: vat_mode}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [201]
    auth: x-billbee-api-key
  } {
    shop_id: $shop_id, accept_loss_of_return_right: $accept_loss_of_return_right, adjustment_cost: $adjustment_cost, adjustment_reason: $adjustment_reason, api_account_id: $api_account_id, api_account_name: $api_account_name, archived_at: $archived_at, bill_bee_order_id: $bill_bee_order_id, bill_bee_parent_order_id: $bill_bee_parent_order_id, buyer: $buyer, comments: $comments, confirmed_at: $confirmed_at, created_at: $created_at, currency: $currency, custom_invoice_note: $custom_invoice_note, customer: $customer, customer_number: $customer_number, customer_vat_id: $customer_vat_id, delivery_source_country_code: $delivery_source_country_code, distribution_center: $distribution_center, history: $history, id: $id, invoice_address: $invoice_address, invoice_date: $invoice_date, invoice_number: $invoice_number, invoice_number_postfix: $invoice_number_postfix, invoice_number_prefix: $invoice_number_prefix, is_cancelation_for: $is_cancelation_for, is_from_billbee_api: $is_from_billbee_api, language_code: $language_code, last_modified_at: $last_modified_at, merchant_vat_id: $merchant_vat_id, order_items: $order_items, order_number: $order_number, paid_amount: $paid_amount, payed_at: $payed_at, payment_instruction: $payment_instruction, payment_method: $payment_method, payment_reference: $payment_reference, payment_transaction_id: $payment_transaction_id, payments: $payments, restored_at: $restored_at, seller: $seller, seller_comment: $seller_comment, ship_weight_kg: $ship_weight_kg, shipped_at: $shipped_at, shipping_address: $shipping_address, shipping_cost: $shipping_cost, shipping_ids: $shipping_ids, shipping_profile_id: $shipping_profile_id, shipping_profile_name: $shipping_profile_name, shipping_provider_id: $shipping_provider_id, shipping_provider_name: $shipping_provider_name, shipping_provider_product_id: $shipping_provider_product_id, shipping_provider_product_name: $shipping_provider_product_name, shipping_services: $shipping_services, state: $state, tags: $tags, tax_rate1: $tax_rate1, tax_rate2: $tax_rate2, total_cost: $total_cost, updated_at: $updated_at, vat_id: $vat_id, vat_mode: $vat_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an delivery note for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateDeliveryNote/{id}
# Returns: record
# operationId: OrderApi_CreateDeliveryNote
export def "order-api-create-delivery-note" [
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
  --accept: string@accept-completer # Response content type
  --include-pdf: oneof<nothing, bool> # If true, the PDF is included in the response as base64 encoded string
  --send-to-cloud-id: int # Optionally specify the id of a billbee connected cloud device to send the pdf to (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/orders/CreateDeliveryNote/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: includePdf, var: include_pdf}, {name: sendToCloudId, var: send_to_cloud_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, include_pdf: $include_pdf, send_to_cloud_id: $send_to_cloud_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an invoice for an existing order. This request is extra throttled by order and api key to a maximum of 1 per 5 minutes.
#
# POST /api/v1/orders/CreateInvoice/{id}
# Returns: record
# operationId: OrderApi_CreateInvoice
export def "order-api-create-invoice" [
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
  --accept: string@accept-completer # Response content type
  --include-invoice-pdf: oneof<nothing, bool> # If true, the PDF is included in the response as base64 encoded string
  --template-id: int # You can pass the id of an invoice template to overwrite the assigned template for invoice creation (format: int64)
  --send-to-cloud-id: int # You can pass the id of a connected cloud printer/storage to send the invoice to it (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/orders/CreateInvoice/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: includeInvoicePdf, var: include_invoice_pdf}, {name: templateId, var: template_id}, {name: sendToCloudId, var: send_to_cloud_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, include_invoice_pdf: $include_invoice_pdf, template_id: $template_id, send_to_cloud_id: $send_to_cloud_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of fields which can be updated with the orders/{id} patch call
#
# GET /api/v1/orders/PatchableFields
# Returns: record
# operationId: OrderApi_GetPatchableFields
export def "order-api-get-patchable-fields" [
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
    path: "/api/v1/orders/PatchableFields"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Find a single order by its external id (order number)
#
# GET /api/v1/orders/find/{id}/{partner}
# DEPRECATED
# Returns: record
# operationId: OrderApi_Find
@deprecated
export def "order-api-find" [
  id: string
  partner: string
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
    path: "/api/v1/orders/find/{id}/{partner}"
    path_params: [{name: id, var: id}, {name: partner, var: partner}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, partner: $partner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a single order by its external order number
#
# GET /api/v1/orders/findbyextref/{extRef}
# Returns: record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: OrderApi_GetByExtRef
export def "order-api-get-by-ext-ref" [
  ext_ref: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/orders/findbyextref/{extRef}"
    path_params: [{name: extRef, var: ext_ref}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    ext_ref: $ext_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all invoices optionally filtered by date. This request ist throttled to 1 per 1 minute for same page and minInvoiceDate
#
# GET /api/v1/orders/invoices
# Returns: record
# operationId: OrderApi_GetInvoiceList
export def "order-api-get-invoice-list" [
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
  --min-invoice-date: string # Specifies the oldest invoice date to include (format: date-time)
  --max-invoice-date: string # Specifies the newest invoice date to include (format: date-time)
  --page: int # Specifies the page to request (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --shop-id: list<int> # Specifies a list of shop ids for which invoices should be included
  --order-state-id: list<int> # Specifies a list of state ids to include in the response
  --tag: list<string>
  --min-pay-date: string # format: date-time
  --max-pay-date: string # format: date-time
  --include-positions: oneof<nothing, bool>
  --exclude-tags: oneof<nothing, bool> # If true the list of tags passed to the call are used to filter orders to not include these tags
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/orders/invoices"
    query: [{name: minInvoiceDate, var: min_invoice_date}, {name: maxInvoiceDate, var: max_invoice_date}, {name: page, var: page}, {name: pageSize, var: page_size}, {name: shopId, var: shop_id, style: multi}, {name: orderStateId, var: order_state_id, style: multi}, {name: tag, var: tag, style: multi}, {name: minPayDate, var: min_pay_date}, {name: maxPayDate, var: max_pay_date}, {name: includePositions, var: include_positions}, {name: excludeTags, var: exclude_tags}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    min_invoice_date: $min_invoice_date, max_invoice_date: $max_invoice_date, page: $page, page_size: $page_size, shop_id: $shop_id, order_state_id: $order_state_id, tag: $tag, min_pay_date: $min_pay_date, max_pay_date: $max_pay_date, include_positions: $include_positions, exclude_tags: $exclude_tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a single order by its internal billbee id. This request is throttled to 6 calls per order in one minute
#
# GET /api/v1/orders/{id}
# Returns: record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: OrderApi_Get
export def "order-api-get" [
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
  --accept: string@accept-completer-1 # Response content type
  --article-title-source: int@article-title-source-completer # The source field for the article title. 0 = Order Position (default), 1 = Article Title, 2 = Article Invoice Text (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: articleTitleSource, var: article_title_source}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, article_title_source: $article_title_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates one or more fields of an order
#
# PATCH /api/v1/orders/{id}
# Returns: record<Data: record<AcceptLossOfReturnRight: bool, AdjustmentCost: float, AdjustmentReason: string, ApiAccountId: int, ApiAccountName: string, ArchivedAt: string, BillBeeOrderId: int, BillBeeParentOrderId: int, Buyer: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, Comments: list<record>, ConfirmedAt: string, CreatedAt: string, Currency: string, CustomInvoiceNote: string, Customer: record<ArchivedAt: string, DefaultCommercialMailAddress: record, DefaultFax: record, DefaultMailAddress: record, DefaultPhone1: record, DefaultPhone2: record, DefaultStatusUpdatesMailAddress: record, Email: string, Id: int, LanguageId: int, MetaData: list, Name: string, Number: int, PriceGroupId: int, RestoredAt: string, Tel1: string, Tel2: string, Type: int, VatId: string>, CustomerNumber: string, CustomerVatId: string, DeliverySourceCountryCode: string, DistributionCenter: string, History: list<record>, Id: string, InvoiceAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, InvoiceDate: string, InvoiceNumber: int, InvoiceNumberPostfix: string, InvoiceNumberPrefix: string, IsCancelationFor: string, IsFromBillbeeApi: bool, LanguageCode: string, LastModifiedAt: string, MerchantVatId: string, OrderItems: list<record>, OrderNumber: string, PaidAmount: float, PayedAt: string, PaymentInstruction: string, PaymentMethod: int, PaymentReference: string, PaymentTransactionId: string, Payments: list<record>, RebateDifference: float, RestoredAt: string, Seller: record<BillbeeShopId: int, BillbeeShopName: string, Email: string, FirstName: string, FullName: string, Id: string, LastName: string, Nick: string, Platform: string>, SellerComment: string, ShipWeightKg: float, ShippedAt: string, ShippingAddress: record<BillbeeId: int, City: string, Company: string, Country: string, CountryISO2: string, Email: string, FirstName: string, HouseNumber: string, LastName: string, Line2: string, NameAddition: string, Phone: string, State: string, Street: string, Zip: string>, ShippingCost: float, ShippingIds: list<record>, ShippingProfileId: string, ShippingProfileName: string, ShippingProviderId: int, ShippingProviderName: string, ShippingProviderProductId: int, ShippingProviderProductName: string, ShippingServices: list<record>, State: int, Tags: list<string>, TaxRate1: float, TaxRate2: float, TotalCost: float, UpdatedAt: string, VatId: string, VatMode: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: OrderApi_PatchOrder
export def "order-api-patch-order" [
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
  --accept: string@accept-completer-1 # Response content type
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/orders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Changes the main state of a single order
#
# PUT /api/v1/orders/{id}/orderstate
# Returns: record
# operationId: OrderApi_UpdateState
export def "order-api-update-state" [
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
  --accept: string@accept-completer # Response content type
  --new-state-id: int@new-state-id-completer # The new state to set (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/orders/{id}/orderstate"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: NewStateId, var: new_state_id}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, new_state_id: $new_state_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Parses a text and replaces all placeholders
#
# POST /api/v1/orders/{id}/parse-placeholders
# Returns: record
# operationId: OrderApi_ParsePlaceholders
export def "order-api-parse-placeholders" [
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
  --accept: string@accept-completer # Response content type
  --is-html: oneof<nothing, bool> # If true, the string will be handled as html.
  --language: string # The ISO 639-1 code of the target language. Using default if not set.
  --text-to-parse: string # The text to parse and replace the placeholders in.
  --trim: oneof<nothing, bool> # If true, then the placeholder values are trimmed after usage.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders/{id}/parse-placeholders"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: IsHtml, var: is_html}, {name: Language, var: language}, {name: TextToParse, var: text_to_parse}, {name: Trim, var: trim}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, is_html: $is_html, language: $language, text_to_parse: $text_to_parse, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sends a message to the buyer
#
# POST /api/v1/orders/{id}/send-message
# Returns: record
# operationId: OrderApi_SendMessage
export def "order-api-send-message" [
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
  --accept: string@accept-completer # Response content type
  --alternative-mail: string
  --body: list # item shape: {LanguageCode?: string, Text?: string}
  --send-mode: int@send-mode-completer # format: int32
  --subject: list # item shape: {LanguageCode?: string, Text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders/{id}/send-message"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AlternativeMail, var: alternative_mail}, {name: Body, var: body}, {name: SendMode, var: send_mode}, {name: Subject, var: subject}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, alternative_mail: $alternative_mail, body: $body, send_mode: $send_mode, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a shipment to a given order
#
# POST /api/v1/orders/{id}/shipment
# Returns: record
# operationId: OrderApi_AddShipment
export def "order-api-add-shipment" [
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
  --accept: string@accept-completer # Response content type
  --carrier-id: int # Optional the id of a shipping carrier that should be assigend to the shipment Will override the carrier from the shipment product. Please use the integer value from this Enumeration: {Billbee.Interfaces.Shipping.Enums.ShippingCarrier} (format: int32)
  --comment: string # Optional a text stored with the shipment
  --order-id: string # Optional a differing order number of the shipment if available
  --shipment-type: int # 0 if Shipment, 1 if Retoure {Billbee.Interfaces.Shipping.Enums.ShipmentTypeEnum} (format: int32)
  --shipping-id: string # The id of the shipment (Sendungsnummer/trackingid)
  --shipping-provider-id: int # Optional the id of a shipping provider existing in the billbee account that should be assigned to the shipment (format: int64)
  --shipping-provider-product-id: int # Optional the id of a shipping provider product that should be assigend to the shipment (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders/{id}/shipment"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CarrierId, var: carrier_id}, {name: Comment, var: comment}, {name: OrderId, var: order_id}, {name: ShipmentType, var: shipment_type}, {name: ShippingId, var: shipping_id}, {name: ShippingProviderId, var: shipping_provider_id}, {name: ShippingProviderProductId, var: shipping_provider_product_id}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, carrier_id: $carrier_id, comment: $comment, order_id: $order_id, shipment_type: $shipment_type, shipping_id: $shipping_id, shipping_provider_id: $shipping_provider_id, shipping_provider_product_id: $shipping_provider_product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Attach one or more tags to an order
#
# POST /api/v1/orders/{id}/tags
# Returns: record
# operationId: OrderApi_TagsCreate
export def "order-api-tags-create" [
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
  --accept: string@accept-completer # Response content type
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders/{id}/tags"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sets the tags attached to an order
#
# PUT /api/v1/orders/{id}/tags
# Returns: record
# operationId: OrderApi_TagsUpdate
export def "order-api-tags-update" [
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
  --accept: string@accept-completer # Response content type
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/orders/{id}/tags"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Triggers a rule event
#
# POST /api/v1/orders/{id}/trigger-event
# Returns: record
# operationId: OrderApi_TriggerEvent
export def "order-api-trigger-event" [
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
  --accept: string@accept-completer # Response content type
  --delay-in-minutes: int # The delay in minutes until the rule is executed (format: int32)
  --name: string # Name of the event
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/orders/{id}/trigger-event"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DelayInMinutes, var: delay_in_minutes}, {name: Name, var: name}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, delay_in_minutes: $delay_in_minutes, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all products
#
# GET /api/v1/products
# Returns: record<Data: table<BasicAttributes: list, BillOfMaterial: list, Category1: record, Category2: record, Category3: record, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list, DeliveryTime: int, Description: list, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list, HeightCm: float, Id: int, Images: list, InvoiceText: list, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list, Tags: list, TaricNumber: string, Title: list, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Article_GetList
export def "article-get-list" [
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
  --page: int # The current page to request starting with 1 (format: int32)
  --page-size: int # The pagesize for the result list. Values between 1 and 250 are allowed (format: int32)
  --min-created-at: string # Optional the oldest create date of the articles to be returned (format: date-time)
  --minimum-bill-bee-article-id: int # format: int64
  --maximum-bill-bee-article-id: int # format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: minCreatedAt, var: min_created_at}, {name: minimumBillBeeArticleId, var: minimum_bill_bee_article_id}, {name: maximumBillBeeArticleId, var: maximum_bill_bee_article_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    page: $page, page_size: $page_size, min_created_at: $min_created_at, minimum_bill_bee_article_id: $minimum_bill_bee_article_id, maximum_bill_bee_article_id: $maximum_bill_bee_article_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new product
#
# POST /api/v1/products
# Returns: record
# operationId: Article_CreateArticle
export def "article-create-article" [
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
  --basic-attributes: list # item shape: {LanguageCode?: string, Text?: string}
  --bill-of-material: list # item shape: {Amount?: float, ArticleId?: int, SKU?: string}
  --category1: record # shape: {Id?: int, Name?: string}
  --category2: record # shape: {Id?: int, Name?: string}
  --category3: record # shape: {Id?: int, Name?: string}
  --condition: int # format: int32
  --cost-price: float # format: double
  --country-of-origin: string
  --custom-fields: list # item shape: {ArticleId?: int, Definition?: record, DefinitionId?: int, Id?: int, Value?: record}
  --delivery-time: int # format: int32
  --description: list # item shape: {LanguageCode?: string, Text?: string}
  --ean: string
  --export-description: string
  --export-description-multi-language: list # item shape: {LanguageCode?: string, Text?: string}
  --height-cm: float # format: double
  --id: int # format: int64
  --images: list # item shape: {ArticleId?: int, Id?: int, IsDefault?: bool, Position?: int, ThumbPathExt?: string, ThumbUrl?: string, Url?: string}
  --invoice-text: list # item shape: {LanguageCode?: string, Text?: string}
  --is-customizable: oneof<nothing, bool>
  --is-deactivated: oneof<nothing, bool>
  --is-digital: oneof<nothing, bool>
  --length-cm: float # format: double
  --manufacturer: string
  --materials: list # item shape: {LanguageCode?: string, Text?: string}
  --occasion: int # format: int32
  price: float # format: double
  --recipient: int # format: int32
  --sku: string
  --shipping-product-id: int # format: int64
  --short-description: list # item shape: {LanguageCode?: string, Text?: string}
  --sold-amount: float # format: double
  --sold-amount-last30-days: float # format: double
  --sold-sum-gross: float # format: double
  --sold-sum-gross-last30-days: float # format: double
  --sold-sum-net: float # format: double
  --sold-sum-net-last30-days: float # format: double
  --sources: list # item shape: {ApiAccountId?: int, ApiAccountName?: string, Custom?: record, ExportFactor?: float, Id?: int, Source: string, SourceId: string, StockSyncInactive?: bool, StockSyncMax?: float, StockSyncMin?: float, UnitsPerItem?: float}
  --stock-code: string
  --stock-current: float # format: double
  --stock-desired: float # format: double
  --stock-reduce-items-per-sale: float # format: double
  --stock-warning: float # format: double
  --stocks: list # item shape: {Name?: string, StockCode?: string, StockCurrent?: float, StockDesired?: float, StockId?: int, StockWarning?: float, UnfulfilledAmount?: float}
  --tags: list # item shape: {LanguageCode?: string, Text?: string}
  --taric-number: string
  --title: list # item shape: {LanguageCode?: string, Text?: string}
  type: int # format: int32
  --unit: int # format: int32
  --units-per-item: float # format: double
  vat1_rate: float # format: double
  vat2_rate: float # format: double
  vat_index: int # format: int32
  --weight: int # format: int32
  --weight-net: int # format: int32
  --width-cm: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/products"
    body: {content_type: "application/json", kind: json, fields: [{name: BasicAttributes, var: basic_attributes}, {name: BillOfMaterial, var: bill_of_material}, {name: Category1, var: category1}, {name: Category2, var: category2}, {name: Category3, var: category3}, {name: Condition, var: condition}, {name: CostPrice, var: cost_price}, {name: CountryOfOrigin, var: country_of_origin}, {name: CustomFields, var: custom_fields}, {name: DeliveryTime, var: delivery_time}, {name: Description, var: description}, {name: EAN, var: ean}, {name: ExportDescription, var: export_description}, {name: ExportDescriptionMultiLanguage, var: export_description_multi_language}, {name: HeightCm, var: height_cm}, {name: Id, var: id}, {name: Images, var: images}, {name: InvoiceText, var: invoice_text}, {name: IsCustomizable, var: is_customizable, required: true}, {name: IsDeactivated, var: is_deactivated}, {name: IsDigital, var: is_digital, required: true}, {name: LengthCm, var: length_cm}, {name: Manufacturer, var: manufacturer}, {name: Materials, var: materials}, {name: Occasion, var: occasion}, {name: Price, var: price}, {name: Recipient, var: recipient}, {name: SKU, var: sku}, {name: ShippingProductId, var: shipping_product_id}, {name: ShortDescription, var: short_description}, {name: SoldAmount, var: sold_amount}, {name: SoldAmountLast30Days, var: sold_amount_last30_days}, {name: SoldSumGross, var: sold_sum_gross}, {name: SoldSumGrossLast30Days, var: sold_sum_gross_last30_days}, {name: SoldSumNet, var: sold_sum_net}, {name: SoldSumNetLast30Days, var: sold_sum_net_last30_days}, {name: Sources, var: sources}, {name: StockCode, var: stock_code}, {name: StockCurrent, var: stock_current}, {name: StockDesired, var: stock_desired}, {name: StockReduceItemsPerSale, var: stock_reduce_items_per_sale}, {name: StockWarning, var: stock_warning}, {name: Stocks, var: stocks}, {name: Tags, var: tags}, {name: TaricNumber, var: taric_number}, {name: Title, var: title}, {name: Type, var: type}, {name: Unit, var: unit}, {name: UnitsPerItem, var: units_per_item}, {name: Vat1Rate, var: vat1_rate}, {name: Vat2Rate, var: vat2_rate}, {name: VatIndex, var: vat_index}, {name: Weight, var: weight}, {name: WeightNet, var: weight_net}, {name: WidthCm, var: width_cm}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    basic_attributes: $basic_attributes, bill_of_material: $bill_of_material, category1: $category1, category2: $category2, category3: $category3, condition: $condition, cost_price: $cost_price, country_of_origin: $country_of_origin, custom_fields: $custom_fields, delivery_time: $delivery_time, description: $description, ean: $ean, export_description: $export_description, export_description_multi_language: $export_description_multi_language, height_cm: $height_cm, id: $id, images: $images, invoice_text: $invoice_text, is_customizable: $is_customizable, is_deactivated: $is_deactivated, is_digital: $is_digital, length_cm: $length_cm, manufacturer: $manufacturer, materials: $materials, occasion: $occasion, price: $price, recipient: $recipient, sku: $sku, shipping_product_id: $shipping_product_id, short_description: $short_description, sold_amount: $sold_amount, sold_amount_last30_days: $sold_amount_last30_days, sold_sum_gross: $sold_sum_gross, sold_sum_gross_last30_days: $sold_sum_gross_last30_days, sold_sum_net: $sold_sum_net, sold_sum_net_last30_days: $sold_sum_net_last30_days, sources: $sources, stock_code: $stock_code, stock_current: $stock_current, stock_desired: $stock_desired, stock_reduce_items_per_sale: $stock_reduce_items_per_sale, stock_warning: $stock_warning, stocks: $stocks, tags: $tags, taric_number: $taric_number, title: $title, type: $type, unit: $unit, units_per_item: $units_per_item, vat1_rate: $vat1_rate, vat2_rate: $vat2_rate, vat_index: $vat_index, weight: $weight, weight_net: $weight_net, width_cm: $width_cm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of fields which can be updated with the patch call
#
# GET /api/v1/products/PatchableFields
# Returns: record
# operationId: Article_GetPatchableFields
export def "article-get-patchable-fields" [
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
    path: "/api/v1/products/PatchableFields"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GEts a list of all defined categories
#
# GET /api/v1/products/category
# Returns: record
# operationId: Article_GetCategory
export def "article-get-category" [
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
    path: "/api/v1/products/category"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a list of all custom fields
#
# GET /api/v1/products/custom-fields
# Returns: record<Data: table<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Article_GetCustomFields
export def "article-get-custom-fields" [
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
  --page: int # format: int32
  --page-size: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/custom-fields"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a single custom field
#
# GET /api/v1/products/custom-fields/{id}
# Returns: record<Data: record<Configuration: record, Id: int, IsNullable: bool, Name: string, Type: int>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetCustomField
export def "article-get-custom-field" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/custom-fields/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete multiple images by id
#
# POST /api/v1/products/images/delete
# Returns: record<Data: record<Deleted: list<int>, NotFound: list<int>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_DeleteImages
export def "article-delete-images" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/products/images/delete"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a single image by id
#
# DELETE /api/v1/products/images/{imageId}
# Returns: record
# operationId: Article_DeleteImage
export def "article-delete-image" [
  image_id: int
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
    path: "/api/v1/products/images/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a single image by id
#
# GET /api/v1/products/images/{imageId}
# Returns: record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetImage
export def "article-get-image" [
  image_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/images/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries the reserved amount for a single article by id or by sku
#
# GET /api/v1/products/reservedamount
# Returns: record<Data: record<ReservedAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetReservedAmount
export def "article-get-reserved-amount" [
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
  --id: string # The id or the sku of the article to query (required)
  --lookup-by: string # Either the value id or the value sku to specify the meaning of the id parameter
  --stock-id: int # Optional the stock id if the multi stock feature is enabled (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/reservedamount"
    query: [{name: id, var: id, required: true}, {name: lookupBy, var: lookup_by}, {name: stockId, var: stock_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, lookup_by: $lookup_by, stock_id: $stock_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Query all defined stock locations
#
# GET /api/v1/products/stocks
# Returns: record<Data: table<Description: string, Id: int, IsDefault: bool, Name: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetStocks
export def "article-get-stocks" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/stocks"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the stock qty of an article
#
# POST /api/v1/products/updatestock
# Returns: record<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_UpdateStock
export def "article-update-stock" [
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
  --autosubtract-reserved-amount: oneof<nothing, bool> # Automatically reduce the NewQuantity by the currently not fulfilled amount
  --billbee-id: int # Optional the ID of the Billbee product to update (format: int64)
  --delta-quantity: float # This parameter is currently ignored (format: double)
  --force-send-stock-to-shops: oneof<nothing, bool> # If true, every sent stockchange is stored and transmitted to the connected shop, even if the value has not changed
  --new-quantity: float # The new absolute stock quantity for the product you want to set (format: double)
  --old-quantity: float # This parameter is currently ignored (format: double)
  --reason: string # Optional a reason text for the stock update
  --sku: string # The SKU of the product to update
  --stock-id: int # Optional the stock id if the feature multi stock is activated (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/products/updatestock"
    body: {content_type: "application/json", kind: json, fields: [{name: AutosubtractReservedAmount, var: autosubtract_reserved_amount}, {name: BillbeeId, var: billbee_id}, {name: DeltaQuantity, var: delta_quantity}, {name: ForceSendStockToShops, var: force_send_stock_to_shops}, {name: NewQuantity, var: new_quantity}, {name: OldQuantity, var: old_quantity}, {name: Reason, var: reason}, {name: Sku, var: sku}, {name: StockId, var: stock_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    autosubtract_reserved_amount: $autosubtract_reserved_amount, billbee_id: $billbee_id, delta_quantity: $delta_quantity, force_send_stock_to_shops: $force_send_stock_to_shops, new_quantity: $new_quantity, old_quantity: $old_quantity, reason: $reason, sku: $sku, stock_id: $stock_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the stock code of an article
#
# POST /api/v1/products/updatestockcode
# Returns: record<Data: record, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_UpdateStockCode
export def "article-update-stock-code" [
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
  --billbee-id: int # format: int64
  --sku: string
  --stock-code: string
  --stock-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/products/updatestockcode"
    body: {content_type: "application/json", kind: json, fields: [{name: BillbeeId, var: billbee_id}, {name: Sku, var: sku}, {name: StockCode, var: stock_code}, {name: StockId, var: stock_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    billbee_id: $billbee_id, sku: $sku, stock_code: $stock_code, stock_id: $stock_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the stock qty for multiple articles at once
#
# POST /api/v1/products/updatestockmultiple
# Returns: table<Data: record<CurrentStock: float, Message: string, OldStock: float, SKU: string, UnfulfilledAmount: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_UpdateStockMultiple
export def "article-update-stock-multiple" [
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/products/updatestockmultiple"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a product
#
# DELETE /api/v1/products/{id}
# Returns: record
# operationId: Article_DeleteArticle
export def "article-delete-article" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/api/v1/products/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries a single article by id or by sku
#
# GET /api/v1/products/{id}
# Returns: record<Data: record<BasicAttributes: list<record>, BillOfMaterial: list<record>, Category1: record<Id: int, Name: string>, Category2: record<Id: int, Name: string>, Category3: record<Id: int, Name: string>, Condition: int, CostPrice: float, CountryOfOrigin: string, CustomFields: list<record>, DeliveryTime: int, Description: list<record>, EAN: string, ExportDescription: string, ExportDescriptionMultiLanguage: list<record>, HeightCm: float, Id: int, Images: list<record>, InvoiceText: list<record>, IsCustomizable: bool, IsDeactivated: bool, IsDigital: bool, LengthCm: float, LowStock: bool, Manufacturer: string, Materials: list<record>, Occasion: int, Price: float, Recipient: int, SKU: string, ShippingProductId: int, ShortDescription: list<record>, SoldAmount: float, SoldAmountLast30Days: float, SoldSumGross: float, SoldSumGrossLast30Days: float, SoldSumNet: float, SoldSumNetLast30Days: float, Sources: list<record>, StockCode: string, StockCurrent: float, StockDesired: float, StockReduceItemsPerSale: float, StockWarning: float, Stocks: list<record>, Tags: list<record>, TaricNumber: string, Title: list<record>, Type: int, Unit: int, UnitsPerItem: float, Vat1Rate: float, Vat2Rate: float, VatIndex: int, Weight: int, WeightNet: int, WidthCm: float>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetArticle
export def "article-get-article" [
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
  --lookup-by: string # Either the value id, ean or the value sku to specify the meaning of the id parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: lookupBy, var: lookup_by}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, lookup_by: $lookup_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates one or more fields of a product
#
# PATCH /api/v1/products/{id}
# Returns: record
# operationId: Article_PatchArticle
export def "article-patch-article" [
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
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/v1/products/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of all images of the product
#
# GET /api/v1/products/{productId}/images
# Returns: record<Data: table<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetImages
export def "article-get-images" [
  product_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/{productId}/images"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add multiple images to a product or replace the product images by the given images
#
# PUT /api/v1/products/{productId}/images
# Returns: record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_PutImages
export def "article-put-images" [
  product_id: int
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
  --replace: oneof<nothing, bool> # If you pass true, the images will be replaced by the passed images. Otherwise the passed images will be appended to the product.
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/products/{productId}/images"
    path_params: [{name: productId, var: product_id}]
    query: [{name: replace, var: replace}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    product_id: $product_id, replace: $replace, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a single image from a product
#
# DELETE /api/v1/products/{productId}/images/{imageId}
# Returns: record
# operationId: Article_DeleteImageFromProduct
export def "article-delete-image-from-product" [
  product_id: int
  image_id: int
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
    path: "/api/v1/products/{productId}/images/{imageId}"
    path_params: [{name: productId, var: product_id}, {name: imageId, var: image_id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    product_id: $product_id, image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a single image by id
#
# GET /api/v1/products/{productId}/images/{imageId}
# Returns: record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_GetImageFromProduct
export def "article-get-image-from-product" [
  product_id: int
  image_id: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/products/{productId}/images/{imageId}"
    path_params: [{name: productId, var: product_id}, {name: imageId, var: image_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    product_id: $product_id, image_id: $image_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add or update an existing image of a product
#
# PUT /api/v1/products/{productId}/images/{imageId}
# Returns: record<Data: record<ArticleId: int, Id: int, IsDefault: bool, Position: int, ThumbPathExt: string, ThumbUrl: string, Url: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Article_PutImage
export def "article-put-image" [
  product_id: int
  image_id: int
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
  --article-id: int # format: int64
  --id: int # format: int64
  --is-default: oneof<nothing, bool>
  --position: int # format: int32
  --thumb-path-ext: string
  --thumb-url: string
  --url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/products/{productId}/images/{imageId}"
    path_params: [{name: productId, var: product_id}, {name: imageId, var: image_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArticleId, var: article_id}, {name: Id, var: id}, {name: IsDefault, var: is_default}, {name: Position, var: position}, {name: ThumbPathExt, var: thumb_path_ext}, {name: ThumbUrl, var: thumb_url}, {name: Url, var: url}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    product_id: $product_id, image_id: $image_id, article_id: $article_id, id: $id, is_default: $is_default, position: $position, thumb_path_ext: $thumb_path_ext, thumb_url: $thumb_url, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for products, customers and orders. Type can be "order", "product" and / or "customer" Term can contains lucene query syntax
#
# POST /api/v1/search
# Returns: record<Data: record<Customers: list<record>, Orders: list<record>, Products: list<record>>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Search_Search
export def "search-search" [
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
  --search-mode: int@search-mode-completer # format: int32
  --term: string
  --type: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/search"
    body: {content_type: "application/json", kind: json, fields: [{name: SearchMode, var: search_mode}, {name: Term, var: term}, {name: Type, var: type}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    search_mode: $search_mode, term: $term, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/v1/shipment/ping
#
# Returns: record
# operationId: Shipment_GetPing
export def "shipment-get-ping" [
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
    path: "/api/v1/shipment/ping"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new shipment with the selected Shippingprovider
#
# POST /api/v1/shipment/shipment
# Returns: record
# operationId: Shipment_PostShipment
export def "shipment-post-shipment" [
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
  --client-reference: string # Optional specify a text to be included on the label. Not possible with all carriers
  --content: string # Optional specify a text describing the content of the shipment. Used for export shipments
  --customer-number: string # Not used anymore
  --dimension: record # shape: {height?: float, length?: float, width?: float}
  --order-currency-code: string # The Currency if the ordersum
  --order-sum: float # The value of the shipments content (format: double)
  --printer-id-for-export-docs: int # The id of a connected Cloudprinter to sent the export docs to (format: int64)
  --printer-name: string # The name of a connected Cloudprinter to sent the label to
  --product-code: string # The productcode to be used when creating the shipment. Values depends on the carrier used
  --provider-name: string # The name of the provider as specified in the billbee account
  --receiver-address: record # shape: {AddressAddition?: string, City?: string, Company?: string, CountryCode?: string, CountryCodeISO3?: string, Email?: string, FirstName?: string, Housenumber?: string, IsExportCountry?: bool, LastName?: string, Name2?: string, State?: string, Street?: string, Telephone?: string, Zip?: string}
  --services: list # A list of services to be used when creating the shipment
  --ship-date: string # Optional overwrite the shipdate to be transferred to the carrier (format: date-time)
  --total-net: float # The value of the shipments content (net) (format: double)
  --weight-in-gram: float # Optional specify the weight in gram of the shipment (format: double)
  --shipping-carrier: int@shipping-carrier-completer # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/shipment/shipment"
    body: {content_type: "application/json", kind: json, fields: [{name: ClientReference, var: client_reference}, {name: Content, var: content}, {name: CustomerNumber, var: customer_number}, {name: Dimension, var: dimension}, {name: OrderCurrencyCode, var: order_currency_code}, {name: OrderSum, var: order_sum}, {name: PrinterIdForExportDocs, var: printer_id_for_export_docs}, {name: PrinterName, var: printer_name}, {name: ProductCode, var: product_code}, {name: ProviderName, var: provider_name}, {name: ReceiverAddress, var: receiver_address}, {name: Services, var: services}, {name: ShipDate, var: ship_date}, {name: TotalNet, var: total_net}, {name: WeightInGram, var: weight_in_gram}, {name: shippingCarrier, var: shipping_carrier}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    client_reference: $client_reference, content: $content, customer_number: $customer_number, dimension: $dimension, order_currency_code: $order_currency_code, order_sum: $order_sum, printer_id_for_export_docs: $printer_id_for_export_docs, printer_name: $printer_name, product_code: $product_code, provider_name: $provider_name, receiver_address: $receiver_address, services: $services, ship_date: $ship_date, total_net: $total_net, weight_in_gram: $weight_in_gram, shipping_carrier: $shipping_carrier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of all shipments optionally filtered by date. All parameters are optional.
#
# GET /api/v1/shipment/shipments
# Returns: record<Data: table<BillbeeId: int, Created: string, ShipmentType: int, Shipper: string, ShippingCarrier: int, ShippingId: string, ShippingProviderId: int, ShippingProviderProductId: int, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string, Paging: record<Page: int, PageSize: int, TotalPages: int, TotalRows: int>>
# operationId: Shipment_GetList
export def "shipment-get-list" [
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
  --page: int # Specifies the page to request. (format: int32)
  --page-size: int # Specifies the pagesize. Defaults to 50, max value is 250 (format: int32)
  --created-at-min: string # Specifies the oldest shipment date to include in the response (format: date-time)
  --created-at-max: string # Specifies the newest shipment date to include in the response (format: date-time)
  --order-id: int # Get shipments for this order only. (format: int64)
  --minimum-shipment-id: int # Get Shipments with a shipment greater or equal than this id. New shipments have a greater id than older shipments. (format: int64)
  --shipping-provider-id: int # Get Shippings for the specified shipping provider only. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/shipment/shipments"
    query: [{name: page, var: page}, {name: pageSize, var: page_size}, {name: createdAtMin, var: created_at_min}, {name: createdAtMax, var: created_at_max}, {name: orderId, var: order_id}, {name: minimumShipmentId, var: minimum_shipment_id}, {name: shippingProviderId, var: shipping_provider_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    page: $page, page_size: $page_size, created_at_min: $created_at_min, created_at_max: $created_at_max, order_id: $order_id, minimum_shipment_id: $minimum_shipment_id, shipping_provider_id: $shipping_provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries the currently available shipping carriers.
#
# GET /api/v1/shipment/shippingcarriers
# Returns: record
# operationId: Shipment_GetShippingCarrier
export def "shipment-get-shipping-carrier" [
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
    path: "/api/v1/shipment/shippingcarriers"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Query all defined shipping providers
#
# GET /api/v1/shipment/shippingproviders
# Returns: record
# operationId: Shipment_GetShippingproviders
export def "shipment-get-shippingproviders" [
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
    path: "/api/v1/shipment/shippingproviders"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a shipment for an order in billbee
#
# POST /api/v1/shipment/shipwithlabel
# Returns: record<Data: record<Carrier: string, ExportDocsPdf: string, LabelDataPdf: string, OrderId: int, OrderReference: string, ShippingDate: string, ShippingId: string, TrackingUrl: string>, ErrorCode: int, ErrorDescription: int, ErrorMessage: string>
# operationId: Shipment_ShipWithLabel
export def "shipment-ship-with-label" [
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
  --change-state-to-send: oneof<nothing, bool> # Optional parameter to automatically change the orderstate to sent after creating the shipment
  --client-reference: string # Optional specify a reference text to be included on the label. Works not with all carriers
  --dimension: record # shape: {height?: float, length?: float, width?: float}
  --order-id: int # The Billbee internal id of the order to ship (format: int64)
  --printer-name: string # Optional the name of a connected cloudprinter to send the label to
  --product-id: int # the id of the shipping provider product to be used (format: int64)
  --provider-id: int # The id of the provider. You can query all providers with the shippingproviders endpoint (format: int64)
  --ship-date: string # Optional specify the shipdate to be transmitted to the carrier (format: date-time)
  --weight-in-gram: int # Optional the shipments weight in gram to override the calculated weight (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/shipment/shipwithlabel"
    body: {content_type: "application/json", kind: json, fields: [{name: ChangeStateToSend, var: change_state_to_send}, {name: ClientReference, var: client_reference}, {name: Dimension, var: dimension}, {name: OrderId, var: order_id}, {name: PrinterName, var: printer_name}, {name: ProductId, var: product_id}, {name: ProviderId, var: provider_id}, {name: ShipDate, var: ship_date}, {name: WeightInGram, var: weight_in_gram}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    change_state_to_send: $change_state_to_send, client_reference: $client_reference, dimension: $dimension, order_id: $order_id, printer_name: $printer_name, product_id: $product_id, provider_id: $provider_id, ship_date: $ship_date, weight_in_gram: $weight_in_gram
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes all existing WebHook registrations.
#
# DELETE /api/v1/webhooks
# Returns: record
# operationId: WebHookManagement_DeleteAll
export def "web-hook-management-delete-all" [
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
    path: "/api/v1/webhooks"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all registered WebHooks for a given user.
#
# GET /api/v1/webhooks
# Returns: table<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>
# operationId: WebHookManagement_Get
export def "web-hook-management-get" [
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
    path: "/api/v1/webhooks"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Registers a new WebHook for a given user.
#
# POST /api/v1/webhooks
# Returns: record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>
# operationId: WebHookManagement_Post
export def "web-hook-management-post" [
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
  --description: string
  --filters: list<string>
  --headers: record
  --id: string
  --is-paused: oneof<nothing, bool>
  --properties: record
  secret: string
  web_hook_uri: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Filters, var: filters}, {name: Headers, var: headers}, {name: Id, var: id}, {name: IsPaused, var: is_paused}, {name: Properties, var: properties}, {name: Secret, var: secret}, {name: WebHookUri, var: web_hook_uri}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    description: $description, filters: $filters, headers: $headers, id: $id, is_paused: $is_paused, properties: $properties, secret: $secret, web_hook_uri: $web_hook_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a list of all known filters you can use to register webhooks
#
# GET /api/v1/webhooks/filters
# Returns: record
# operationId: WebHookManagement_GetFilters
export def "web-hook-management-get-filters" [
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
    path: "/api/v1/webhooks/filters"
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes an existing WebHook registration.
#
# DELETE /api/v1/webhooks/{id}
# Returns: record
# operationId: WebHookManagement_Delete
export def "web-hook-management-delete" [
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
    method: delete
    path: "/api/v1/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Looks up a registered WebHook with the given {id} for a given user.
#
# GET /api/v1/webhooks/{id}
# Returns: record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>
# operationId: WebHookManagement_Lookup
export def "web-hook-management-lookup" [
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
    path: "/api/v1/webhooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates an existing WebHook registration.
#
# PUT /api/v1/webhooks/{id}
# Returns: record<Description: string, Filters: list<string>, Headers: record, Id: string, IsPaused: bool, Properties: record, Secret: string, WebHookUri: string>
# operationId: WebHookManagement_Put
export def "web-hook-management-put" [
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
  --description: string
  --filters: list<string>
  --headers: record
  --body-id: string # (spec name: Id)
  --is-paused: oneof<nothing, bool>
  --properties: record
  secret: string
  web_hook_uri: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/webhooks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Filters, var: filters}, {name: Headers, var: headers}, {name: Id, var: body_id}, {name: IsPaused, var: is_paused}, {name: Properties, var: properties}, {name: Secret, var: secret}, {name: WebHookUri, var: web_hook_uri}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: x-billbee-api-key
  } {
    id: $id, description: $description, filters: $filters, headers: $headers, body_id: $body_id, is_paused: $is_paused, properties: $properties, secret: $secret, web_hook_uri: $web_hook_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
