# Auto-generated client for Meraki Dashboard API v0.0.0-streaming
# Source: https://api.apis.guru/v2/specs/meraki.com/0.0.0-streaming/openapi.json
# Auth: --token flag or $env.MERAKI_DASHBOARD_API_TOKEN

const CLIENT = {
  base_url: "https://api.meraki.com/api/v0"
  token_env_var: "MERAKI_DASHBOARD_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-cisco-meraki-api-key, in: header, header_name: X-Cisco-Meraki-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.meraki.com/api/v0"] }
def auth-scheme-completer [] { ["x-cisco-meraki-api-key"] }

# Completers for enum parameters
def object-type-completer [] { ["person" "vehicle"] }
def motion-detector-version-completer [] { ["1" "2"] }
def quality-completer [] { ["Enhanced" "High" "Standard"] }
def resolution-completer [] { ["1080x1080" "1280x720" "1920x1080" "2058x2058"] }
def major-minor-assignment-mode-completer [] { ["Non-unique" "Unique"] }
def band-completer [] { ["2.4" "5"] }
def device-policy-completer [] { ["Allowed" "Blocked" "Group policy" "Normal" "Per connection" "Whitelisted"] }
def url-category-list-size-completer [] { ["fullList" "topSites"] }
def uplink-completer [] { ["cellular" "wan1" "wan2"] }
def access-completer [] { ["blocked" "restricted" "unrestricted"] }
def type-completer [] { ["delete" "restrict processing"] }
def ids-rulesets-completer [] { ["balanced" "connectivity" "security"] }
def mode-completer [] { ["detection" "disabled" "prevention"] }
def mode-completer-1 [] { ["disabled" "enabled"] }
def mode-completer-2 [] { ["hub" "none" "spoke"] }
def ssid-number-completer [] { ["0" "1" "10" "11" "12" "13" "14" "2" "3" "4" "5" "6" "7" "8" "9"] }
def auth-mode-completer [] { ["8021x-google" "8021x-localradius" "8021x-meraki" "8021x-nac" "8021x-radius" "ipsk-with-radius" "ipsk-without-radius" "open" "open-enhanced" "open-with-nac" "open-with-radius" "psk"] }
def encryption-mode-completer [] { ["wep" "wpa"] }
def enterprise-admin-access-completer [] { ["access disabled" "access enabled"] }
def radius-failover-policy-completer [] { ["Allow access" "Deny access"] }
def radius-load-balancing-policy-completer [] { ["Round robin" "Strict priority order"] }
def splash-page-completer [] { ["Billing" "Cisco ISE" "Click-through splash page" "Facebook Wi-Fi" "Google Apps domain" "Google OAuth" "None" "Password-protected with Active Directory" "Password-protected with LDAP" "Password-protected with Meraki RADIUS" "Password-protected with custom RADIUS" "SMS authentication" "Sponsored guest" "Systems Manager Sentry"] }
def wpa-encryption-mode-completer [] { ["WPA1 and WPA2" "WPA1 only" "WPA2 only" "WPA3 Transition Mode" "WPA3 only"] }
def protocol-completer [] { ["ANY" "TCP" "UDP"] }
def device-type-completer [] { ["appliance" "combined" "switch" "wireless"] }
def dhcp-handling-completer [] { ["Do not respond to DHCP requests" "Relay DHCP to another server" "Run a DHCP server"] }
def dhcp-lease-time-completer [] { ["1 day" "1 hour" "1 week" "12 hours" "30 minutes" "4 hours"] }
def band-selection-type-completer [] { ["ap" "ssid"] }
def min-bitrate-type-completer [] { ["band" "ssid"] }
def upgrade-strategy-completer [] { ["minimizeClientDowntime" "minimizeUpgradeTime"] }
def status-completer [] { ["completed" "failed" "pending"] }
def authentication-method-completer [] { ["Cisco SecureX Sign-On" "Email"] }
def org-access-completer [] { ["enterprise" "full" "none" "read-only"] }
def state-completer [] { ["active" "expired" "expiring" "recentlyQueued" "unused" "unusedActive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-device-camera-analytics-live: "record"
    get-device-camera-analytics-overview: "list<record>"
    get-device-camera-analytics-recent: "list<record>"
    get-device-camera-analytics-zones: "list<record>"
    get-device-camera-analytics-zone-history: "list<record>"
    get-device-camera-quality-and-retention-settings: "record"
    update-device-camera-quality-and-retention-settings: "record"
    get-device-camera-video-settings: "record"
    update-device-camera-video-settings: "record"
    get-device-cellular-gateway-settings: "record"
    update-device-cellular-gateway-settings: "record"
    get-device-cellular-gateway-settings-port-forwarding-rules: "record"
    update-device-cellular-gateway-settings-port-forwarding-rules: "record"
    get-device-clients: "list<record>"
    cycle-device-switch-ports: "record"
    get-device-switch-port-statuses: "list<record>"
    get-device-switch-port-statuses-packets: "list<record>"
    update-device-wireless-bluetooth-settings: "record<major: int, minor: int, uuid: string>"
    get-network: "record"
    update-network: "record"
    get-network-access-policies: "list<record>"
    get-network-air-marshal: "list<record>"
    get-network-alert-settings: "record"
    update-network-alert-settings: "record"
    get-network-appliance-firewall-inbound-firewall-rules: "record"
    update-network-appliance-firewall-inbound-firewall-rules: "record"
    get-network-appliance-ports: "list<record>"
    get-network-appliance-port: "record"
    update-network-appliance-port: "record"
    get-network-bluetooth-clients: "list<record>"
    get-network-bluetooth-client: "record"
    get-network-bluetooth-settings: "record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string>"
    update-network-bluetooth-settings: "record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string>"
    get-network-camera-quality-retention-profiles: "list<record>"
    create-network-camera-quality-retention-profile: "record"
    get-network-camera-quality-retention-profile: "record"
    update-network-camera-quality-retention-profile: "record"
    get-network-camera-schedules: "list<record>"
    generate-network-camera-snapshot: "record"
    get-network-camera-video-link: "record"
    get-network-cellular-firewall-rules: "list<record>"
    update-network-cellular-firewall-rules: "list<record>"
    get-network-clients: "record<description: string, firstSeen: int, groupPolicy8021x: string, id: string, ip: string, ip6: string, ip6Local: string, lastSeen: int, mac: string, manufacturer: string, notes: string, os: string, recentDeviceMac: string, recentDeviceName: string, recentDeviceSerial: string, smInstalled: bool, ssid: string, status: string, switchport: string, usage: record<recv: float, sent: float>, user: string, vlan: string>"
    get-network-clients-connection-stats: "list<record>"
    get-network-clients-latency-stats: "list<record>"
    provision-network-clients: "record"
    get-network-client: "record"
    get-network-client-connection-stats: "record"
    get-network-client-events: "list<record>"
    get-network-client-latency-history: "list<record>"
    get-network-client-latency-stats: "record"
    get-network-client-policy: "record"
    update-network-client-policy: "record"
    get-network-client-splash-authorization-status: "record"
    update-network-client-splash-authorization-status: "record"
    get-network-client-usage-history: "list<record>"
    get-network-connection-stats: "record"
    get-network-content-filtering: "record"
    update-network-content-filtering: "record"
    get-network-content-filtering-categories: "record"
    get-network-devices: "list<record>"
    get-network-devices-connection-stats: "list<record>"
    get-network-devices-latency-stats: "list<record>"
    get-network-device: "record"
    update-network-device: "record"
    get-network-device-connection-stats: "record"
    get-network-device-latency-stats: "record"
    get-network-device-loss-and-latency-history: "list<record>"
    get-network-device-performance: "record"
    reboot-network-device: "record"
    get-network-device-uplink: "list<record>"
    get-network-device-wireless-status: "record"
    get-network-events: "record"
    get-network-events-event-types: "list<record>"
    get-network-failed-connections: "list<record>"
    get-network-firewalled-services: "list<record>"
    get-network-firewalled-service: "record"
    update-network-firewalled-service: "record"
    get-network-floor-plans: "list<record>"
    create-network-floor-plan: "record"
    get-network-floor-plan: "record"
    update-network-floor-plan: "record"
    get-network-l3-firewall-rules: "list<record>"
    update-network-l3-firewall-rules: "list<record>"
    get-network-l7-firewall-rules: "record"
    update-network-l7-firewall-rules: "record"
    get-network-l7-firewall-rules-application-categories: "record"
    get-network-latency-stats: "record"
    get-network-meraki-auth-users: "list<record>"
    get-network-meraki-auth-user: "record"
    get-network-one-to-many-nat-rules: "record"
    update-network-one-to-many-nat-rules: "record"
    get-network-one-to-one-nat-rules: "record"
    update-network-one-to-one-nat-rules: "record"
    get-network-pii-pii-keys: "record"
    get-network-pii-requests: "list<record>"
    create-network-pii-request: "record"
    get-network-pii-request: "record"
    get-network-pii-sm-devices-for-key: "record"
    get-network-pii-sm-owners-for-key: "record"
    get-network-port-forwarding-rules: "record"
    update-network-port-forwarding-rules: "record"
    get-network-security-intrusion-settings: "record"
    update-network-security-intrusion-settings: "record"
    get-network-security-malware-settings: "record"
    update-network-security-malware-settings: "record"
    get-network-security-events: "list<record>"
    get-network-site-to-site-vpn: "record"
    update-network-site-to-site-vpn: "record"
    create-network-sm-bypass-activation-lock-attempt: "record"
    get-network-sm-bypass-activation-lock-attempt: "record"
    update-network-sm-device-fields: "record"
    wipe-network-sm-device: "record"
    get-network-sm-devices: "record"
    checkin-network-sm-devices: "record"
    update-network-sm-devices-tags: "record"
    unenroll-network-sm-device: "record"
    get-network-sm-profiles: "record"
    get-network-sm-target-groups: "list<record>"
    create-network-sm-target-group: "record"
    get-network-sm-target-group: "record"
    update-network-sm-target-group: "record"
    get-network-sm-user-device-profiles: "list<record>"
    get-network-sm-user-softwares: "list<record>"
    get-network-sm-users: "list<record>"
    get-network-sm-cellular-usage-history: "list<record>"
    get-network-sm-certs: "list<record>"
    get-network-sm-device-profiles: "list<record>"
    get-network-sm-network-adapters: "list<record>"
    get-network-sm-restrictions: "list<record>"
    get-network-sm-security-centers: "list<record>"
    get-network-sm-softwares: "list<record>"
    get-network-sm-wlan-lists: "list<record>"
    get-network-snmp-settings: "record"
    get-network-splash-login-attempts: "list<record>"
    split-network: "record"
    get-network-ssids: "list<record>"
    get-network-ssid: "record"
    update-network-ssid: "record"
    get-network-ssid-l3-firewall-rules: "list<record>"
    update-network-ssid-l3-firewall-rules: "list<record>"
    get-network-ssid-splash-settings: "record"
    update-network-ssid-splash-settings: "record"
    get-network-static-routes: "list<record>"
    create-network-static-route: "record"
    get-network-static-route: "record"
    update-network-static-route: "record"
    swap-network-warm-spare: "record"
    get-network-switch-link-aggregations: "list<record>"
    create-network-switch-link-aggregation: "record"
    update-network-switch-link-aggregation: "record"
    get-network-switch-port-schedules: "list<record>"
    create-network-switch-port-schedule: "record"
    update-network-switch-port-schedule: "record"
    get-network-switch-settings: "record"
    update-network-switch-settings: "record"
    get-network-switch-settings-mtu: "record"
    update-network-switch-settings-mtu: "record"
    get-network-switch-settings-multicast: "record"
    update-network-switch-settings-multicast: "record"
    get-network-switch-settings-qos-rules: "list<record>"
    create-network-switch-settings-qos-rule: "record"
    get-network-switch-settings-qos-rules-order: "record"
    update-network-switch-settings-qos-rules-order: "record"
    get-network-switch-settings-qos-rule: "record"
    update-network-switch-settings-qos-rule: "record"
    get-network-switch-settings-storm-control: "record"
    update-network-switch-settings-storm-control: "record"
    get-network-switch-stacks: "list<record>"
    create-network-switch-stack: "record"
    get-network-switch-stack: "record"
    add-network-switch-stack: "record"
    remove-network-switch-stack: "record"
    get-network-syslog-servers: "list<record>"
    update-network-syslog-servers: "list<record>"
    get-network-traffic: "list<record>"
    get-network-uplink-settings: "record"
    update-network-uplink-settings: "record"
    get-network-vlans: "list<record>"
    create-network-vlan: "record"
    get-network-vlan: "record"
    update-network-vlan: "record"
    get-network-vlans-enabled-state: "record"
    update-network-vlans-enabled-state: "record"
    get-network-warm-spare-settings: "record"
    update-network-warm-spare-settings: "record"
    get-network-wireless-rf-profiles: "list<record>"
    create-network-wireless-rf-profile: "record"
    get-network-wireless-rf-profile: "record"
    update-network-wireless-rf-profile: "record"
    get-network-wireless-settings: "record"
    update-network-wireless-settings: "record"
    lock-network-sm-devices: "record"
    get-network-sm-connectivity: "list<record>"
    get-network-sm-desktop-logs: "list<record>"
    get-network-sm-device-command-logs: "list<record>"
    get-network-sm-performance-history: "list<record>"
    get-organizations: "list<record>"
    get-organization: "record"
    get-organization-action-batches: "list<record>"
    create-organization-action-batch: "record"
    update-organization-action-batch: "record"
    get-organization-admins: "list<record>"
    create-organization-admin: "record"
    update-organization-admin: "record"
    get-organization-api-requests: "list<record>"
    get-organization-api-requests-overview: "record"
    claim-into-organization: "record"
    clone-organization: "record"
    get-organization-config-templates: "list<record>"
    get-organization-config-template-switch-profiles: "list<record>"
    get-organization-configuration-changes: "list<record>"
    get-organization-device-statuses: "list<record>"
    get-organization-devices: "list<record>"
    get-organization-insight-monitored-media-servers: "list<record>"
    create-organization-insight-monitored-media-server: "record"
    get-organization-insight-monitored-media-server: "record"
    update-organization-insight-monitored-media-server: "record"
    get-organization-inventory: "list<record>"
    get-organization-license-state: "record"
    get-organization-licenses: "list<record>"
    assign-organization-licenses-seats: "record"
    move-organization-licenses-seats: "record"
    renew-organization-licenses-seats: "record"
    get-organization-license: "record"
    get-organization-networks: "list<record>"
    create-organization-network: "record"
    combine-organization-networks: "record"
    get-organization-openapi-spec: "record"
    get-organization-saml-roles: "list<record>"
    create-organization-saml-role: "record"
    get-organization-saml-role: "record"
    update-organization-saml-role: "record"
    get-organization-security-intrusion-settings: "record"
    update-organization-security-intrusion-settings: "record"
    get-organization-security-events: "list<record>"
    get-organization-snmp: "record"
    get-organization-third-party-vpn-peers: "list<record>"
    update-organization-third-party-vpn-peers: "list<record>"
    get-organization-uplinks-loss-and-latency: "list<record>"
    get-organization-vpn-firewall-rules: "list<record>"
    update-organization-vpn-firewall-rules: "list<record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-device-camera-analytics-live" "get-device-camera-analytics-overview" "get-device-camera-analytics-recent" "get-device-camera-analytics-zones" "get-device-camera-analytics-zone-history" "get-device-camera-quality-and-retention-settings" "update-device-camera-quality-and-retention-settings" "get-device-camera-video-settings" "update-device-camera-video-settings" "get-device-cellular-gateway-settings" "update-device-cellular-gateway-settings" "get-device-cellular-gateway-settings-port-forwarding-rules" "update-device-cellular-gateway-settings-port-forwarding-rules" "get-device-clients" "cycle-device-switch-ports" "get-device-switch-port-statuses" "get-device-switch-port-statuses-packets" "update-device-wireless-bluetooth-settings" "delete-network" "get-network" "update-network" "get-network-access-policies" "get-network-air-marshal" "get-network-alert-settings" "update-network-alert-settings" "get-network-appliance-firewall-inbound-firewall-rules" "update-network-appliance-firewall-inbound-firewall-rules" "get-network-appliance-ports" "get-network-appliance-port" "update-network-appliance-port" "bind-network" "get-network-bluetooth-clients" "get-network-bluetooth-client" "get-network-bluetooth-settings" "update-network-bluetooth-settings" "get-network-camera-quality-retention-profiles" "create-network-camera-quality-retention-profile" "delete-network-camera-quality-retention-profile" "get-network-camera-quality-retention-profile" "update-network-camera-quality-retention-profile" "get-network-camera-schedules" "generate-network-camera-snapshot" "get-network-camera-video-link" "get-network-cellular-firewall-rules" "update-network-cellular-firewall-rules" "get-network-clients" "get-network-clients-connection-stats" "get-network-clients-latency-stats" "provision-network-clients" "get-network-client" "get-network-client-connection-stats" "get-network-client-events" "get-network-client-latency-history" "get-network-client-latency-stats" "get-network-client-policy" "update-network-client-policy" "get-network-client-splash-authorization-status" "update-network-client-splash-authorization-status" "get-network-client-usage-history" "get-network-connection-stats" "get-network-content-filtering" "update-network-content-filtering" "get-network-content-filtering-categories" "get-network-devices" "claim-network-devices" "get-network-devices-connection-stats" "get-network-devices-latency-stats" "get-network-device" "update-network-device" "get-network-device-connection-stats" "get-network-device-latency-stats" "get-network-device-loss-and-latency-history" "get-network-device-performance" "reboot-network-device" "remove-network-device" "get-network-device-uplink" "get-network-device-wireless-status" "get-network-events" "get-network-events-event-types" "get-network-failed-connections" "get-network-firewalled-services" "get-network-firewalled-service" "update-network-firewalled-service" "get-network-floor-plans" "create-network-floor-plan" "delete-network-floor-plan" "get-network-floor-plan" "update-network-floor-plan" "get-network-l3-firewall-rules" "update-network-l3-firewall-rules" "get-network-l7-firewall-rules" "update-network-l7-firewall-rules" "get-network-l7-firewall-rules-application-categories" "get-network-latency-stats" "get-network-meraki-auth-users" "get-network-meraki-auth-user" "get-network-one-to-many-nat-rules" "update-network-one-to-many-nat-rules" "get-network-one-to-one-nat-rules" "update-network-one-to-one-nat-rules" "get-network-pii-pii-keys" "get-network-pii-requests" "create-network-pii-request" "delete-network-pii-request" "get-network-pii-request" "get-network-pii-sm-devices-for-key" "get-network-pii-sm-owners-for-key" "get-network-port-forwarding-rules" "update-network-port-forwarding-rules" "get-network-security-intrusion-settings" "update-network-security-intrusion-settings" "get-network-security-malware-settings" "update-network-security-malware-settings" "get-network-security-events" "get-network-site-to-site-vpn" "update-network-site-to-site-vpn" "create-network-sm-bypass-activation-lock-attempt" "get-network-sm-bypass-activation-lock-attempt" "update-network-sm-device-fields" "wipe-network-sm-device" "refresh-network-sm-device-details" "get-network-sm-devices" "checkin-network-sm-devices" "update-network-sm-devices-tags" "unenroll-network-sm-device" "get-network-sm-profiles" "get-network-sm-target-groups" "create-network-sm-target-group" "delete-network-sm-target-group" "get-network-sm-target-group" "update-network-sm-target-group" "get-network-sm-user-device-profiles" "get-network-sm-user-softwares" "get-network-sm-users" "get-network-sm-cellular-usage-history" "get-network-sm-certs" "get-network-sm-device-profiles" "get-network-sm-network-adapters" "get-network-sm-restrictions" "get-network-sm-security-centers" "get-network-sm-softwares" "get-network-sm-wlan-lists" "get-network-snmp-settings" "get-network-splash-login-attempts" "split-network" "get-network-ssids" "get-network-ssid" "update-network-ssid" "get-network-ssid-l3-firewall-rules" "update-network-ssid-l3-firewall-rules" "get-network-ssid-splash-settings" "update-network-ssid-splash-settings" "get-network-static-routes" "create-network-static-route" "delete-network-static-route" "get-network-static-route" "update-network-static-route" "swap-network-warm-spare" "get-network-switch-link-aggregations" "create-network-switch-link-aggregation" "delete-network-switch-link-aggregation" "update-network-switch-link-aggregation" "get-network-switch-port-schedules" "create-network-switch-port-schedule" "delete-network-switch-port-schedule" "update-network-switch-port-schedule" "get-network-switch-settings" "update-network-switch-settings" "get-network-switch-settings-mtu" "update-network-switch-settings-mtu" "get-network-switch-settings-multicast" "update-network-switch-settings-multicast" "get-network-switch-settings-qos-rules" "create-network-switch-settings-qos-rule" "get-network-switch-settings-qos-rules-order" "update-network-switch-settings-qos-rules-order" "delete-network-switch-settings-qos-rule" "get-network-switch-settings-qos-rule" "update-network-switch-settings-qos-rule" "get-network-switch-settings-storm-control" "update-network-switch-settings-storm-control" "get-network-switch-stacks" "create-network-switch-stack" "delete-network-switch-stack" "get-network-switch-stack" "add-network-switch-stack" "remove-network-switch-stack" "get-network-syslog-servers" "update-network-syslog-servers" "get-network-traffic" "unbind-network" "get-network-uplink-settings" "update-network-uplink-settings" "get-network-vlans" "create-network-vlan" "delete-network-vlan" "get-network-vlan" "update-network-vlan" "get-network-vlans-enabled-state" "update-network-vlans-enabled-state" "get-network-warm-spare-settings" "update-network-warm-spare-settings" "get-network-wireless-rf-profiles" "create-network-wireless-rf-profile" "delete-network-wireless-rf-profile" "get-network-wireless-rf-profile" "update-network-wireless-rf-profile" "get-network-wireless-settings" "update-network-wireless-settings" "lock-network-sm-devices" "get-network-sm-connectivity" "get-network-sm-desktop-logs" "get-network-sm-device-command-logs" "get-network-sm-performance-history" "get-organizations" "get-organization" "get-organization-action-batches" "create-organization-action-batch" "delete-organization-action-batch" "update-organization-action-batch" "get-organization-admins" "create-organization-admin" "delete-organization-admin" "update-organization-admin" "get-organization-api-requests" "get-organization-api-requests-overview" "claim-into-organization" "clone-organization" "get-organization-config-templates" "delete-organization-config-template" "get-organization-config-template-switch-profiles" "get-organization-configuration-changes" "get-organization-device-statuses" "get-organization-devices" "get-organization-insight-monitored-media-servers" "create-organization-insight-monitored-media-server" "delete-organization-insight-monitored-media-server" "get-organization-insight-monitored-media-server" "update-organization-insight-monitored-media-server" "get-organization-inventory" "get-organization-license-state" "get-organization-licenses" "assign-organization-licenses-seats" "move-organization-licenses-seats" "renew-organization-licenses-seats" "get-organization-license" "get-organization-networks" "create-organization-network" "combine-organization-networks" "get-organization-openapi-spec" "get-organization-saml-roles" "create-organization-saml-role" "get-organization-saml-role" "update-organization-saml-role" "get-organization-security-intrusion-settings" "update-organization-security-intrusion-settings" "get-organization-security-events" "get-organization-snmp" "get-organization-third-party-vpn-peers" "update-organization-third-party-vpn-peers" "get-organization-uplinks-loss-and-latency" "get-organization-vpn-firewall-rules" "update-organization-vpn-firewall-rules" "commands"] | sort) } | get name | first)
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

# Returns live state from camera of analytics zones
#
# GET /devices/{serial}/camera/analytics/live
# Returns: record
# operationId: getDeviceCameraAnalyticsLive
export def "get-device-camera-analytics-live" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/devices/{serial}/camera/analytics/live"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an overview of aggregate analytics data for a timespan
#
# GET /devices/{serial}/camera/analytics/overview
# Returns: list<record>
# operationId: getDeviceCameraAnalyticsOverview
export def "get-device-camera-analytics-overview" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. The default is 1 hour. (format: float)
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/camera/analytics/overview"
    path_params: [{name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: objectType, var: object_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, t0: $t0, t1: $t1, timespan: $timespan, object_type: $object_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns most recent record for analytics zones
#
# GET /devices/{serial}/camera/analytics/recent
# Returns: list<record>
# operationId: getDeviceCameraAnalyticsRecent
export def "get-device-camera-analytics-recent" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/camera/analytics/recent"
    path_params: [{name: serial, var: serial}]
    query: [{name: objectType, var: object_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, object_type: $object_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all configured analytic zones for this camera
#
# GET /devices/{serial}/camera/analytics/zones
# Returns: list<record>
# operationId: getDeviceCameraAnalyticsZones
export def "get-device-camera-analytics-zones" [
  serial: string
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
    path: "/devices/{serial}/camera/analytics/zones"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return historical records for analytic zones
#
# GET /devices/{serial}/camera/analytics/zones/{zoneId}/history
# Returns: list<record>
# operationId: getDeviceCameraAnalyticsZoneHistory
export def "get-device-camera-analytics-zone-history" [
  serial: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 14 hours after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 14 hours. The default is 1 hour. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 60. The default is 60.
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/camera/analytics/zones/{zoneId}/history"
    path_params: [{name: serial, var: serial}, {name: zoneId, var: zone_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: resolution, var: resolution}, {name: objectType, var: object_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, zone_id: $zone_id, t0: $t0, t1: $t1, timespan: $timespan, resolution: $resolution, object_type: $object_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns quality and retention settings for the given camera
#
# GET /devices/{serial}/camera/qualityAndRetentionSettings
# Returns: record
# operationId: getDeviceCameraQualityAndRetentionSettings
export def "get-device-camera-quality-and-retention-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/devices/{serial}/camera/qualityAndRetentionSettings"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update quality and retention settings for the given camera
#
# PUT /devices/{serial}/camera/qualityAndRetentionSettings
# Returns: record
# operationId: updateDeviceCameraQualityAndRetentionSettings
export def "update-device-camera-quality-and-retention-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Boolean indicating if audio recording is enabled(true) or disabled(false) on the camera
  --motion-based-retention-enabled: oneof<nothing, bool> # Boolean indicating if motion-based retention is enabled(true) or disabled(false) on the camera
  --motion-detector-version: int@motion-detector-version-completer # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --profile-id: string # The ID of a quality and retention profile to assign to the camera. The profile's settings will override all of the per-camera quality and retention settings. If the value of this parameter is null, any existing profile will be unassigned from the camera.
  --quality: string@quality-completer # Quality of the camera. Can be one of 'Standard', 'High' or 'Enhanced'. Not all qualities are supported by every camera model.
  --resolution: string@resolution-completer # Resolution of the camera. Can be one of '1280x720', '1920x1080', '1080x1080' or '2058x2058'. Not all resolutions are supported by every camera model.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Boolean indicating if restricted bandwidth is enabled(true) or disabled(false) on the camera. This setting does not apply to MV2 cameras.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{serial}/camera/qualityAndRetentionSettings"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: audioRecordingEnabled, var: audio_recording_enabled}, {name: motionBasedRetentionEnabled, var: motion_based_retention_enabled}, {name: motionDetectorVersion, var: motion_detector_version}, {name: profileId, var: profile_id}, {name: quality, var: quality}, {name: resolution, var: resolution}, {name: restrictedBandwidthModeEnabled, var: restricted_bandwidth_mode_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, audio_recording_enabled: $audio_recording_enabled, motion_based_retention_enabled: $motion_based_retention_enabled, motion_detector_version: $motion_detector_version, profile_id: $profile_id, quality: $quality, resolution: $resolution, restricted_bandwidth_mode_enabled: $restricted_bandwidth_mode_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns video settings for the given camera
#
# GET /devices/{serial}/camera/video/settings
# Returns: record
# operationId: getDeviceCameraVideoSettings
export def "get-device-camera-video-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/devices/{serial}/camera/video/settings"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update video settings for the given camera
#
# PUT /devices/{serial}/camera/video/settings
# Returns: record
# operationId: updateDeviceCameraVideoSettings
export def "update-device-camera-video-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-rtsp-enabled: oneof<nothing, bool> # Boolean indicating if external rtsp stream is exposed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{serial}/camera/video/settings"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalRtspEnabled, var: external_rtsp_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, external_rtsp_enabled: $external_rtsp_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the LAN Settings of a MG
#
# GET /devices/{serial}/cellularGateway/settings
# Returns: record
# operationId: getDeviceCellularGatewaySettings
export def "get-device-cellular-gateway-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/devices/{serial}/cellularGateway/settings"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the LAN Settings for a single MG.
#
# PUT /devices/{serial}/cellularGateway/settings
# Returns: record
# operationId: updateDeviceCellularGatewaySettings
export def "update-device-cellular-gateway-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fixed-ip-assignments: list # list of all fixed IP assignments for a single MG — item shape: {ip: string, mac: string, name?: string}
  --reserved-ip-ranges: list # list of all reserved IP ranges for a single MG — item shape: {comment: string, end: string, start: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{serial}/cellularGateway/settings"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: fixedIpAssignments, var: fixed_ip_assignments}, {name: reservedIpRanges, var: reserved_ip_ranges}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, fixed_ip_assignments: $fixed_ip_assignments, reserved_ip_ranges: $reserved_ip_ranges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the port forwarding rules for a single MG.
#
# GET /devices/{serial}/cellularGateway/settings/portForwardingRules
# Returns: record
# operationId: getDeviceCellularGatewaySettingsPortForwardingRules
export def "get-device-cellular-gateway-settings-port-forwarding-rules" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/devices/{serial}/cellularGateway/settings/portForwardingRules"
    path_params: [{name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the port forwarding rules for a single MG.
#
# PUT /devices/{serial}/cellularGateway/settings/portForwardingRules
# Returns: record
# operationId: updateDeviceCellularGatewaySettingsPortForwardingRules
export def "update-device-cellular-gateway-settings-port-forwarding-rules" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An array of port forwarding params — item shape: {access: string, allowedIps?: list<string>, lanIp: string, localPort: string, name?: string, protocol: string, publicPort: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{serial}/cellularGateway/settings/portForwardingRules"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the clients of a device, up to a maximum of a month ago
#
# GET /devices/{serial}/clients
# Returns: list<record>
# operationId: getDeviceClients
export def "get-device-clients" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/clients"
    path_params: [{name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, t0: $t0, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cycle a set of switch ports
#
# POST /devices/{serial}/switch/ports/cycle
# Returns: record
# operationId: cycleDeviceSwitchPorts
export def "cycle-device-switch-ports" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ports: list<string> # List of switch ports. Example: [1, 2-5, 1_MA-MOD-8X10G_1, 1_MA-MOD-8X10G_2-1_MA-MOD-8X10G_8]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/devices/{serial}/switch/ports/cycle"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: ports, var: ports}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, ports: $ports
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the status for all the ports of a switch
#
# GET /devices/{serial}/switchPortStatuses
# Returns: list<record>
# operationId: getDeviceSwitchPortStatuses
export def "get-device-switch-port-statuses" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/switchPortStatuses"
    path_params: [{name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, t0: $t0, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the packet counters for all the ports of a switch
#
# GET /devices/{serial}/switchPortStatuses/packets
# Returns: list<record>
# operationId: getDeviceSwitchPortStatusesPackets
export def "get-device-switch-port-statuses-packets" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 1 day from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 1 day. The default is 1 day. (format: float)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/{serial}/switchPortStatuses/packets"
    path_params: [{name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, t0: $t0, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the bluetooth settings for a wireless device
#
# PUT /devices/{serial}/wireless/bluetooth/settings
# Returns: record<major: int, minor: int, uuid: string>
# operationId: updateDeviceWirelessBluetoothSettings
export def "update-device-wireless-bluetooth-settings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --major: int # Desired major value of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
  --minor: int # Desired minor value of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
  --uuid: string # Desired UUID of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/devices/{serial}/wireless/bluetooth/settings"
    path_params: [{name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: major, var: major}, {name: minor, var: minor}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    serial: $serial, major: $major, minor: $minor, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a network
#
# DELETE /networks/{networkId}
# operationId: deleteNetwork
export def "delete-network" [
  network_id: string
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
    path: "/networks/{networkId}"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a network
#
# GET /networks/{networkId}
# Returns: record
# operationId: getNetwork
export def "get-network" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a network
#
# PUT /networks/{networkId}
# Returns: record
# operationId: updateNetwork
export def "update-network" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disable-my-meraki-com: oneof<nothing, bool> # Disables the local device status pages (my.meraki.com, ap.meraki.com, switch.meraki.com, wired.meraki.com). Optional (defaults to false)
  --disable-remote-status-page: oneof<nothing, bool> # Disables access to the device status page (http://[device's LAN IP]). Optional. Can only be set if disableMyMerakiCom is set to false
  --enrollment-string: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break.
  --name: string # The name of the network
  --tags: string # A space-separated list of tags to be applied to the network
  --time-zone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in this article.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: disableMyMerakiCom, var: disable_my_meraki_com}, {name: disableRemoteStatusPage, var: disable_remote_status_page}, {name: enrollmentString, var: enrollment_string}, {name: name, var: name}, {name: tags, var: tags}, {name: timeZone, var: time_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, disable_my_meraki_com: $disable_my_meraki_com, disable_remote_status_page: $disable_remote_status_page, enrollment_string: $enrollment_string, name: $name, tags: $tags, time_zone: $time_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the access policies for this network
#
# GET /networks/{networkId}/accessPolicies
# Returns: list<record>
# operationId: getNetworkAccessPolicies
export def "get-network-access-policies" [
  network_id: string
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
    path: "/networks/{networkId}/accessPolicies"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Air Marshal scan results from a network
#
# GET /networks/{networkId}/airMarshal
# Returns: list<record>
# operationId: getNetworkAirMarshal
export def "get-network-air-marshal" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 7 days. (format: float)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/airMarshal"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the alert configuration for this network
#
# GET /networks/{networkId}/alertSettings
# Returns: record
# operationId: getNetworkAlertSettings
export def "get-network-alert-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/alertSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the alert configuration for this network
#
# PUT /networks/{networkId}/alertSettings
# Returns: record
# operationId: updateNetworkAlertSettings
export def "update-network-alert-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alerts: list # Alert-specific configuration for each type. Only alerts that pertain to the network can be updated. — item shape: {alertDestinations?: record, enabled?: bool, filters?: record, type: string}
  --default-destinations: record # The network-wide destinations for all alerts on the network. — shape: {allAdmins?: bool, emails?: list<string>, httpServerIds?: list<string>, snmp?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/alertSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alerts, var: alerts}, {name: defaultDestinations, var: default_destinations}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, alerts: $alerts, default_destinations: $default_destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the inbound firewall rules for an MX network
#
# GET /networks/{networkId}/appliance/firewall/inboundFirewallRules
# Returns: record
# operationId: getNetworkApplianceFirewallInboundFirewallRules
export def "get-network-appliance-firewall-inbound-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/appliance/firewall/inboundFirewallRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the inbound firewall rules of an MX network
#
# PUT /networks/{networkId}/appliance/firewall/inboundFirewallRules
# Returns: record
# operationId: updateNetworkApplianceFirewallInboundFirewallRules
export def "update-network-appliance-firewall-inbound-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/appliance/firewall/inboundFirewallRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}, {name: syslogDefaultRule, var: syslog_default_rule}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules, syslog_default_rule: $syslog_default_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List per-port VLAN settings for all ports of a MX.
#
# GET /networks/{networkId}/appliancePorts
# Returns: list<record>
# operationId: getNetworkAppliancePorts
export def "get-network-appliance-ports" [
  network_id: string
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
    path: "/networks/{networkId}/appliancePorts"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return per-port VLAN settings for a single MX port.
#
# GET /networks/{networkId}/appliancePorts/{appliancePortId}
# Returns: record
# operationId: getNetworkAppliancePort
export def "get-network-appliance-port" [
  network_id: string
  appliance_port_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/appliancePorts/{appliancePortId}"
    path_params: [{name: networkId, var: network_id}, {name: appliancePortId, var: appliance_port_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, appliance_port_id: $appliance_port_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the per-port VLAN settings for a single MX port.
#
# PUT /networks/{networkId}/appliancePorts/{appliancePortId}
# Returns: record
# operationId: updateNetworkAppliancePort
export def "update-network-appliance-port" [
  network_id: string
  appliance_port_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-policy: string # The name of the policy. Only applicable to Access ports. Valid values are: 'open', '8021x-radius', 'mac-radius', 'hybris-radius' for MX64 or Z3 or any MX supporting the per port authentication feature. Otherwise, 'open' is the only valid value and 'open' is the default value if the field is missing.
  --allowed-vlans: string # Comma-delimited list of the VLAN ID's allowed on the port, or 'all' to permit all VLAN's on the port.
  --drop-untagged-traffic: oneof<nothing, bool> # Trunk port can Drop all Untagged traffic. When true, no VLAN is required. Access ports cannot have dropUntaggedTraffic set to true.
  --enabled: oneof<nothing, bool> # The status of the port
  --type: string # The type of the port: 'access' or 'trunk'.
  --vlan: int # Native VLAN when the port is in Trunk mode. Access VLAN when the port is in Access mode.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/appliancePorts/{appliancePortId}"
    path_params: [{name: networkId, var: network_id}, {name: appliancePortId, var: appliance_port_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessPolicy, var: access_policy}, {name: allowedVlans, var: allowed_vlans}, {name: dropUntaggedTraffic, var: drop_untagged_traffic}, {name: enabled, var: enabled}, {name: type, var: type}, {name: vlan, var: vlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, appliance_port_id: $appliance_port_id, access_policy: $access_policy, allowed_vlans: $allowed_vlans, drop_untagged_traffic: $drop_untagged_traffic, enabled: $enabled, type: $type, vlan: $vlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bind a network to a template.
#
# POST /networks/{networkId}/bind
# operationId: bindNetwork
export def "bind-network" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-bind: oneof<nothing, bool> # Optional boolean indicating whether the network's switches should automatically bind to profiles of the same model. Defaults to false if left unspecified. This option only affects switch networks and switch templates. Auto-bind is not valid unless the switch template has at least one profile and has at most one profile per switch model.
  config_template_id: string # The ID of the template to which the network should be bound.
]: any -> any {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/bind"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoBind, var: auto_bind}, {name: configTemplateId, var: config_template_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, auto_bind: $auto_bind, config_template_id: $config_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the Bluetooth clients seen by APs in this network
#
# GET /networks/{networkId}/bluetoothClients
# Returns: list<record>
# operationId: getNetworkBluetoothClients
export def "get-network-bluetooth-clients" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 7 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 7 days. The default is 1 day. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 5 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --include-connectivity-history: oneof<nothing, bool> # Include the connectivity history for this client
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/bluetoothClients"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}, {name: includeConnectivityHistory, var: include_connectivity_history}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before, include_connectivity_history: $include_connectivity_history
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a Bluetooth client
#
# GET /networks/{networkId}/bluetoothClients/{bluetoothClientId}
# Returns: record
# operationId: getNetworkBluetoothClient
export def "get-network-bluetooth-client" [
  network_id: string
  bluetooth_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-connectivity-history: oneof<nothing, bool> # Include the connectivity history for this client
  --connectivity-history-timespan: int # The timespan, in seconds, for the connectivityHistory data. By default 1 day, 86400, will be used.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/bluetoothClients/{bluetoothClientId}"
    path_params: [{name: networkId, var: network_id}, {name: bluetoothClientId, var: bluetooth_client_id}]
    query: [{name: includeConnectivityHistory, var: include_connectivity_history}, {name: connectivityHistoryTimespan, var: connectivity_history_timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, bluetooth_client_id: $bluetooth_client_id, include_connectivity_history: $include_connectivity_history, connectivity_history_timespan: $connectivity_history_timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the Bluetooth settings for a network. Bluetooth settings (https://documentation.meraki.com/MR/Bluetooth/Bluetooth_Low_Energy_(BLE)) must be enabled on the network.
#
# GET /networks/{networkId}/bluetoothSettings
# Returns: record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string>
# operationId: getNetworkBluetoothSettings
export def "get-network-bluetooth-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/bluetoothSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the Bluetooth settings for a network
#
# PUT /networks/{networkId}/bluetoothSettings
# Returns: record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string>
# operationId: updateNetworkBluetoothSettings
export def "update-network-bluetooth-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertising-enabled: oneof<nothing, bool> # Whether APs will advertise beacons.
  --major: int # The major number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --major-minor-assignment-mode: string@major-minor-assignment-mode-completer # The way major and minor number should be assigned to nodes in the network. ('Unique', 'Non-unique')
  --minor: int # The minor number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --scanning-enabled: oneof<nothing, bool> # Whether APs will scan for Bluetooth enabled clients.
  --uuid: string # The UUID to be used in the beacon identifier.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/bluetoothSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: advertisingEnabled, var: advertising_enabled}, {name: major, var: major}, {name: majorMinorAssignmentMode, var: major_minor_assignment_mode}, {name: minor, var: minor}, {name: scanningEnabled, var: scanning_enabled}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, advertising_enabled: $advertising_enabled, major: $major, major_minor_assignment_mode: $major_minor_assignment_mode, minor: $minor, scanning_enabled: $scanning_enabled, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the quality retention profiles for this network
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles
# Returns: list<record>
# operationId: getNetworkCameraQualityRetentionProfiles
export def "get-network-camera-quality-retention-profiles" [
  network_id: string
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
    path: "/networks/{networkId}/camera/qualityRetentionProfiles"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new quality retention profile for this network.
#
# POST /networks/{networkId}/camera/qualityRetentionProfiles
# Returns: record
# operationId: createNetworkCameraQualityRetentionProfile
export def "create-network-camera-quality-retention-profile" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloud-archive-enabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --max-retention-days: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motion-based-retention-enabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motion-detector-version: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  name: string # The name of the new profile. Must be unique. This parameter is required.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --schedule-id: string # Schedule for which this camera will record video, or 'null' to always record.
  --video-settings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/camera/qualityRetentionProfiles"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audioRecordingEnabled, var: audio_recording_enabled}, {name: cloudArchiveEnabled, var: cloud_archive_enabled}, {name: maxRetentionDays, var: max_retention_days}, {name: motionBasedRetentionEnabled, var: motion_based_retention_enabled}, {name: motionDetectorVersion, var: motion_detector_version}, {name: name, var: name}, {name: restrictedBandwidthModeEnabled, var: restricted_bandwidth_mode_enabled}, {name: scheduleId, var: schedule_id}, {name: videoSettings, var: video_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, audio_recording_enabled: $audio_recording_enabled, cloud_archive_enabled: $cloud_archive_enabled, max_retention_days: $max_retention_days, motion_based_retention_enabled: $motion_based_retention_enabled, motion_detector_version: $motion_detector_version, name: $name, restricted_bandwidth_mode_enabled: $restricted_bandwidth_mode_enabled, schedule_id: $schedule_id, video_settings: $video_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing quality retention profile for this network.
#
# DELETE /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: deleteNetworkCameraQualityRetentionProfile
export def "delete-network-camera-quality-retention-profile" [
  network_id: string
  quality_retention_profile_id: string
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
    path: "/networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: qualityRetentionProfileId, var: quality_retention_profile_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, quality_retention_profile_id: $quality_retention_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single quality retention profile
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# Returns: record
# operationId: getNetworkCameraQualityRetentionProfile
export def "get-network-camera-quality-retention-profile" [
  network_id: string
  quality_retention_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: qualityRetentionProfileId, var: quality_retention_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, quality_retention_profile_id: $quality_retention_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing quality retention profile for this network.
#
# PUT /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# Returns: record
# operationId: updateNetworkCameraQualityRetentionProfile
export def "update-network-camera-quality-retention-profile" [
  network_id: string
  quality_retention_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloud-archive-enabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --max-retention-days: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motion-based-retention-enabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motion-detector-version: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --name: string # The name of the new profile. Must be unique.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --schedule-id: string # Schedule for which this camera will record video, or 'null' to always record.
  --video-settings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: qualityRetentionProfileId, var: quality_retention_profile_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audioRecordingEnabled, var: audio_recording_enabled}, {name: cloudArchiveEnabled, var: cloud_archive_enabled}, {name: maxRetentionDays, var: max_retention_days}, {name: motionBasedRetentionEnabled, var: motion_based_retention_enabled}, {name: motionDetectorVersion, var: motion_detector_version}, {name: name, var: name}, {name: restrictedBandwidthModeEnabled, var: restricted_bandwidth_mode_enabled}, {name: scheduleId, var: schedule_id}, {name: videoSettings, var: video_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, quality_retention_profile_id: $quality_retention_profile_id, audio_recording_enabled: $audio_recording_enabled, cloud_archive_enabled: $cloud_archive_enabled, max_retention_days: $max_retention_days, motion_based_retention_enabled: $motion_based_retention_enabled, motion_detector_version: $motion_detector_version, name: $name, restricted_bandwidth_mode_enabled: $restricted_bandwidth_mode_enabled, schedule_id: $schedule_id, video_settings: $video_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all camera recording schedules.
#
# GET /networks/{networkId}/camera/schedules
# Returns: list<record>
# operationId: getNetworkCameraSchedules
export def "get-network-camera-schedules" [
  network_id: string
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
    path: "/networks/{networkId}/camera/schedules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a snapshot of what the camera sees at the specified time and return a link to that image.
#
# POST /networks/{networkId}/cameras/{serial}/snapshot
# Returns: record
# operationId: generateNetworkCameraSnapshot
export def "generate-network-camera-snapshot" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fullframe: oneof<nothing, bool> # [optional] If set to "true" the snapshot will be taken at full sensor resolution. This will error if used with timestamp.
  --timestamp: string # [optional] The snapshot will be taken from this time on the camera. The timestamp is expected to be in ISO 8601 format. If no timestamp is specified, we will assume current time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/cameras/{serial}/snapshot"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: fullframe, var: fullframe}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, fullframe: $fullframe, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns video link to the specified camera
#
# GET /networks/{networkId}/cameras/{serial}/videoLink
# Returns: record
# operationId: getNetworkCameraVideoLink
export def "get-network-camera-video-link" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # [optional] The video link will start at this timestamp. The timestamp is in UNIX Epoch time (milliseconds). If no timestamp is specified, we will assume current time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/cameras/{serial}/videoLink"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    query: [{name: timestamp, var: timestamp}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the cellular firewall rules for an MX network
#
# GET /networks/{networkId}/cellularFirewallRules
# Returns: list<record>
# operationId: getNetworkCellularFirewallRules
export def "get-network-cellular-firewall-rules" [
  network_id: string
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
    path: "/networks/{networkId}/cellularFirewallRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the cellular firewall rules of an MX network
#
# PUT /networks/{networkId}/cellularFirewallRules
# Returns: list<record>
# operationId: updateNetworkCellularFirewallRules
export def "update-network-cellular-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/cellularFirewallRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the clients that have used this network in the timespan
#
# GET /networks/{networkId}/clients
# Returns: record<description: string, firstSeen: int, groupPolicy8021x: string, id: string, ip: string, ip6: string, ip6Local: string, lastSeen: int, mac: string, manufacturer: string, notes: string, os: string, recentDeviceMac: string, recentDeviceName: string, recentDeviceSerial: string, smInstalled: bool, ssid: string, status: string, switchport: string, usage: record<recv: float, sent: float>, user: string, vlan: string>
# operationId: getNetworkClients
export def "get-network-clients" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated connectivity info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/connectionStats
# Returns: list<record>
# operationId: getNetworkClientsConnectionStats
export def "get-network-clients-connection-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/connectionStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated latency info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/latencyStats
# Returns: list<record>
# operationId: getNetworkClientsLatencyStats
export def "get-network-clients-latency-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/latencyStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a client with a name and policy
#
# POST /networks/{networkId}/clients/provision
# Returns: record
# operationId: provisionNetworkClients
export def "provision-network-clients" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_policy: string@device-policy-completer # The policy to apply to the specified client. Can be 'Group policy', 'Whitelisted', 'Allowed', 'Blocked', 'Per connection' or 'Normal'. Required.
  --group-policy-id: string # The ID of the desired group policy to apply to the client. Required if 'devicePolicy' is set to "Group policy". Otherwise this is ignored.
  mac: string # The MAC address of the client. Required.
  --name: string # The display name for the client. Optional. Limited to 255 bytes.
  --policies-by-security-appliance: record # An object, describing what the policy-connection association is for the security appliance. (Only relevant if the security appliance is actually within the network) — shape: {devicePolicy?: "Blocked"|"Normal"|"Whitelisted"}
  --policies-by-ssid: record # An object, describing the policy-connection associations for each active SSID within the network. Keys should be the number of enabled SSIDs, mapping to an object describing the client's policy — shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/clients/provision"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: devicePolicy, var: device_policy}, {name: groupPolicyId, var: group_policy_id}, {name: mac, var: mac}, {name: name, var: name}, {name: policiesBySecurityAppliance, var: policies_by_security_appliance}, {name: policiesBySsid, var: policies_by_ssid}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_policy: $device_policy, group_policy_id: $group_policy_id, mac: $mac, name: $name, policies_by_security_appliance: $policies_by_security_appliance, policies_by_ssid: $policies_by_ssid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the client associated with the given identifier
#
# GET /networks/{networkId}/clients/{clientId}
# Returns: record
# operationId: getNetworkClient
export def "get-network-client" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/clients/{clientId}"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated connectivity info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/connectionStats
# Returns: record
# operationId: getNetworkClientConnectionStats
export def "get-network-client-connection-stats" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/{clientId}/connectionStats"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the events associated with this client
#
# GET /networks/{networkId}/clients/{clientId}/events
# Returns: list<record>
# operationId: getNetworkClientEvents
export def "get-network-client-events" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 100. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/{clientId}/events"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the latency history for a client
#
# GET /networks/{networkId}/clients/{clientId}/latencyHistory
# Returns: list<record>
# operationId: getNetworkClientLatencyHistory
export def "get-network-client-latency-history" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 791 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 791 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 791 days. The default is 1 day. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 86400. The default is 86400.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/{clientId}/latencyHistory"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: resolution, var: resolution}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, t0: $t0, t1: $t1, timespan: $timespan, resolution: $resolution
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated latency info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/latencyStats
# Returns: record
# operationId: getNetworkClientLatencyStats
export def "get-network-client-latency-stats" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/clients/{clientId}/latencyStats"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the policy assigned to a client on the network
#
# GET /networks/{networkId}/clients/{clientId}/policy
# Returns: record
# operationId: getNetworkClientPolicy
export def "get-network-client-policy" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/clients/{clientId}/policy"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the policy assigned to a client on the network
#
# PUT /networks/{networkId}/clients/{clientId}/policy
# Returns: record
# operationId: updateNetworkClientPolicy
export def "update-network-client-policy" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_policy: string # The policy to assign. Can be 'Whitelisted', 'Blocked', 'Normal' or 'Group policy'. Required.
  --group-policy-id: string # [optional] If 'devicePolicy' is set to 'Group policy' this param is used to specify the group policy ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/clients/{clientId}/policy"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: devicePolicy, var: device_policy}, {name: groupPolicyId, var: group_policy_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, device_policy: $device_policy, group_policy_id: $group_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the splash authorization for a client, for each SSID they've associated with through splash
#
# GET /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# Returns: record
# operationId: getNetworkClientSplashAuthorizationStatus
export def "get-network-client-splash-authorization-status" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/clients/{clientId}/splashAuthorizationStatus"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a client's splash authorization
#
# PUT /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# Returns: record
# operationId: updateNetworkClientSplashAuthorizationStatus
export def "update-network-client-splash-authorization-status" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ssids: record # The target SSIDs. Each SSID must be enabled and must have Click-through splash enabled. For each SSID where isAuthorized is true, the expiration time will automatically be set according to the SSID's splash frequency. Not all networks support configuring all SSIDs — shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/clients/{clientId}/splashAuthorizationStatus"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ssids, var: ssids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id, ssids: $ssids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the client's daily usage history
#
# GET /networks/{networkId}/clients/{clientId}/usageHistory
# Returns: list<record>
# operationId: getNetworkClientUsageHistory
export def "get-network-client-usage-history" [
  network_id: string
  client_id: string
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
    path: "/networks/{networkId}/clients/{clientId}/usageHistory"
    path_params: [{name: networkId, var: network_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated connectivity info for this network
#
# GET /networks/{networkId}/connectionStats
# Returns: record
# operationId: getNetworkConnectionStats
export def "get-network-connection-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/connectionStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the content filtering settings for an MX network
#
# GET /networks/{networkId}/contentFiltering
# Returns: record
# operationId: getNetworkContentFiltering
export def "get-network-content-filtering" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/contentFiltering"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the content filtering settings for an MX network
#
# PUT /networks/{networkId}/contentFiltering
# Returns: record
# operationId: updateNetworkContentFiltering
export def "update-network-content-filtering" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-url-patterns: list<string> # A list of URL patterns that are allowed
  --blocked-url-categories: list<string> # A list of URL categories to block
  --blocked-url-patterns: list<string> # A list of URL patterns that are blocked
  --url-category-list-size: string@url-category-list-size-completer # URL category list size which is either 'topSites' or 'fullList'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/contentFiltering"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedUrlPatterns, var: allowed_url_patterns}, {name: blockedUrlCategories, var: blocked_url_categories}, {name: blockedUrlPatterns, var: blocked_url_patterns}, {name: urlCategoryListSize, var: url_category_list_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, allowed_url_patterns: $allowed_url_patterns, blocked_url_categories: $blocked_url_categories, blocked_url_patterns: $blocked_url_patterns, url_category_list_size: $url_category_list_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all available content filtering categories for an MX network
#
# GET /networks/{networkId}/contentFiltering/categories
# Returns: record
# operationId: getNetworkContentFilteringCategories
export def "get-network-content-filtering-categories" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/contentFiltering/categories"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the devices in a network
#
# GET /networks/{networkId}/devices
# Returns: list<record>
# operationId: getNetworkDevices
export def "get-network-devices" [
  network_id: string
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
    path: "/networks/{networkId}/devices"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claim devices into a network. (Note: for recently claimed devices, it may take a few minutes for API requests against that device to succeed)
#
# POST /networks/{networkId}/devices/claim
# operationId: claimNetworkDevices
export def "claim-network-devices" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --serial: string # [DEPRECATED] The serial of a device to claim
  --serials: list<string> # A list of serials of devices to claim
]: any -> any {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/devices/claim"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: serial, var: serial}, {name: serials, var: serials}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, serials: $serials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated connectivity info for this network, grouped by node
#
# GET /networks/{networkId}/devices/connectionStats
# Returns: list<record>
# operationId: getNetworkDevicesConnectionStats
export def "get-network-devices-connection-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/devices/connectionStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated latency info for this network, grouped by node
#
# GET /networks/{networkId}/devices/latencyStats
# Returns: list<record>
# operationId: getNetworkDevicesLatencyStats
export def "get-network-devices-latency-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/devices/latencyStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a single device
#
# GET /networks/{networkId}/devices/{serial}
# Returns: record
# operationId: getNetworkDevice
export def "get-network-device" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/devices/{serial}"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attributes of a device
#
# PUT /networks/{networkId}/devices/{serial}
# Returns: record
# operationId: updateNetworkDevice
export def "update-network-device" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The address of a device
  --floor-plan-id: string # The floor plan to associate to this device. null disassociates the device from the floorplan.
  --lat: float # The latitude of a device (format: float)
  --lng: float # The longitude of a device (format: float)
  --move-map-marker: oneof<nothing, bool> # Whether or not to set the latitude and longitude of a device based on the new address. Only applies when lat and lng are not specified.
  --name: string # The name of a device
  --notes: string # The notes for the device. String. Limited to 255 characters.
  --switch-profile-id: string # The ID of a switch profile to bind to the device (for available switch profiles, see the 'Switch Profiles' endpoint). Use null to unbind the switch device from the current profile. For a device to be bindable to a switch profile, it must (1) be a switch, and (2) belong to a network that is bound to a configuration template.
  --tags: string # The tags of a device
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/devices/{serial}"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: floorPlanId, var: floor_plan_id}, {name: lat, var: lat}, {name: lng, var: lng}, {name: moveMapMarker, var: move_map_marker}, {name: name, var: name}, {name: notes, var: notes}, {name: switchProfileId, var: switch_profile_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, address: $address, floor_plan_id: $floor_plan_id, lat: $lat, lng: $lng, move_map_marker: $move_map_marker, name: $name, notes: $notes, switch_profile_id: $switch_profile_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated connectivity info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/connectionStats
# Returns: record
# operationId: getNetworkDeviceConnectionStats
export def "get-network-device-connection-stats" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/devices/{serial}/connectionStats"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated latency info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/latencyStats
# Returns: record
# operationId: getNetworkDeviceLatencyStats
export def "get-network-device-latency-stats" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/devices/{serial}/latencyStats"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the uplink loss percentage and latency in milliseconds for a wired network device.
#
# GET /networks/{networkId}/devices/{serial}/lossAndLatencyHistory
# Returns: list<record>
# operationId: getNetworkDeviceLossAndLatencyHistory
export def "get-network-device-loss-and-latency-history" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 60 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 60, 600, 3600, 86400. The default is 60.
  --uplink: string@uplink-completer # The WAN uplink used to obtain the requested stats. Valid uplinks are wan1, wan2, cellular. The default is wan1.
  --ip: string # The destination IP used to obtain the requested stats. This is required. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/devices/{serial}/lossAndLatencyHistory"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: resolution, var: resolution}, {name: uplink, var: uplink}, {name: ip, var: ip, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial, t0: $t0, t1: $t1, timespan: $timespan, resolution: $resolution, uplink: $uplink, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the performance score for a single MX
#
# GET /networks/{networkId}/devices/{serial}/performance
# Returns: record
# operationId: getNetworkDevicePerformance
export def "get-network-device-performance" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/devices/{serial}/performance"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboot a device
#
# POST /networks/{networkId}/devices/{serial}/reboot
# Returns: record
# operationId: rebootNetworkDevice
export def "reboot-network-device" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/devices/{serial}/reboot"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a single device
#
# POST /networks/{networkId}/devices/{serial}/remove
# operationId: removeNetworkDevice
export def "remove-network-device" [
  network_id: string
  serial: string
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
    path: "/networks/{networkId}/devices/{serial}/remove"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the uplink information for a device.
#
# GET /networks/{networkId}/devices/{serial}/uplink
# Returns: list<record>
# operationId: getNetworkDeviceUplink
export def "get-network-device-uplink" [
  network_id: string
  serial: string
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
    path: "/networks/{networkId}/devices/{serial}/uplink"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the SSID statuses of an access point
#
# GET /networks/{networkId}/devices/{serial}/wireless/status
# Returns: record
# operationId: getNetworkDeviceWirelessStatus
export def "get-network-device-wireless-status" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/devices/{serial}/wireless/status"
    path_params: [{name: networkId, var: network_id}, {name: serial, var: serial}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the events for the network
#
# GET /networks/{networkId}/events
# Returns: record
# operationId: getNetworkEvents
export def "get-network-events" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string # The product type to fetch events for. This parameter is required for networks with multiple device types. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, and environmental
  --included-event-types: list<string> # A list of event types. The returned events will be filtered to only include events with these types.
  --excluded-event-types: list<string> # A list of event types. The returned events will be filtered to exclude events with these types.
  --device-mac: string # The MAC address of the Meraki device which the list of events will be filtered with
  --device-serial: string # The serial of the Meraki device which the list of events will be filtered with
  --device-name: string # The name of the Meraki device which the list of events will be filtered with
  --client-ip: string # The IP of the client which the list of events will be filtered with. Only supported for track-by-IP networks.
  --client-mac: string # The MAC address of the client which the list of events will be filtered with. Only supported for track-by-MAC networks.
  --client-name: string # The name, or partial name, of the client which the list of events will be filtered with
  --sm-device-mac: string # The MAC address of the Systems Manager device which the list of events will be filtered with
  --sm-device-name: string # The name of the Systems Manager device which the list of events will be filtered with
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/events"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: productType, var: product_type}, {name: includedEventTypes, var: included_event_types, style: csv}, {name: excludedEventTypes, var: excluded_event_types, style: csv}, {name: deviceMac, var: device_mac}, {name: deviceSerial, var: device_serial}, {name: deviceName, var: device_name}, {name: clientIp, var: client_ip}, {name: clientMac, var: client_mac}, {name: clientName, var: client_name}, {name: smDeviceMac, var: sm_device_mac}, {name: smDeviceName, var: sm_device_name}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, product_type: $product_type, included_event_types: $included_event_types, excluded_event_types: $excluded_event_types, device_mac: $device_mac, device_serial: $device_serial, device_name: $device_name, client_ip: $client_ip, client_mac: $client_mac, client_name: $client_name, sm_device_mac: $sm_device_mac, sm_device_name: $sm_device_name, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the event type to human-readable description
#
# GET /networks/{networkId}/events/eventTypes
# Returns: list<record>
# operationId: getNetworkEventsEventTypes
export def "get-network-events-event-types" [
  network_id: string
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
    path: "/networks/{networkId}/events/eventTypes"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of all failed client connection events on this network in a given time range
#
# GET /networks/{networkId}/failedConnections
# Returns: list<record>
# operationId: getNetworkFailedConnections
export def "get-network-failed-connections" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --serial: string # Filter by AP
  --client-id: string # Filter by client MAC
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/failedConnections"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: serial, var: serial}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, serial: $serial, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the appliance services and their accessibility rules
#
# GET /networks/{networkId}/firewalledServices
# Returns: list<record>
# operationId: getNetworkFirewalledServices
export def "get-network-firewalled-services" [
  network_id: string
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
    path: "/networks/{networkId}/firewalledServices"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the accessibility settings of the given service ('ICMP', 'web', or 'SNMP')
#
# GET /networks/{networkId}/firewalledServices/{service}
# Returns: record
# operationId: getNetworkFirewalledService
export def "get-network-firewalled-service" [
  network_id: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/firewalledServices/{service}"
    path_params: [{name: networkId, var: network_id}, {name: service, var: service}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, service: $service
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the accessibility settings for the given service ('ICMP', 'web', or 'SNMP')
#
# PUT /networks/{networkId}/firewalledServices/{service}
# Returns: record
# operationId: updateNetworkFirewalledService
export def "update-network-firewalled-service" [
  network_id: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  access: string@access-completer # A string indicating the rule for which IPs are allowed to use the specified service. Acceptable values are "blocked" (no remote IPs can access the service), "restricted" (only whitelisted IPs can access the service), and "unrestriced" (any remote IP can access the service). This field is required
  --allowed-ips: list<string> # An array of whitelisted IPs that can access the service. This field is required if "access" is set to "restricted". Otherwise this field is ignored
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/firewalledServices/{service}"
    path_params: [{name: networkId, var: network_id}, {name: service, var: service}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: allowedIps, var: allowed_ips}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, service: $service, access: $access, allowed_ips: $allowed_ips
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the floor plans that belong to your network
#
# GET /networks/{networkId}/floorPlans
# Returns: list<record>
# operationId: getNetworkFloorPlans
export def "get-network-floor-plans" [
  network_id: string
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
    path: "/networks/{networkId}/floorPlans"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a floor plan
#
# POST /networks/{networkId}/floorPlans
# Returns: record
# operationId: createNetworkFloorPlan
export def "create-network-floor-plan" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottom-left-corner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottom-right-corner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. The 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  image_contents: string # The file contents (a base 64 encoded string) of your image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. (format: byte)
  name: string # The name of your floor plan.
  --top-left-corner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --top-right-corner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/floorPlans"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bottomLeftCorner, var: bottom_left_corner}, {name: bottomRightCorner, var: bottom_right_corner}, {name: center, var: center}, {name: imageContents, var: image_contents}, {name: name, var: name}, {name: topLeftCorner, var: top_left_corner}, {name: topRightCorner, var: top_right_corner}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, bottom_left_corner: $bottom_left_corner, bottom_right_corner: $bottom_right_corner, center: $center, image_contents: $image_contents, name: $name, top_left_corner: $top_left_corner, top_right_corner: $top_right_corner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Destroy a floor plan
#
# DELETE /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: deleteNetworkFloorPlan
export def "delete-network-floor-plan" [
  network_id: string
  floor_plan_id: string
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
    path: "/networks/{networkId}/floorPlans/{floorPlanId}"
    path_params: [{name: networkId, var: network_id}, {name: floorPlanId, var: floor_plan_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, floor_plan_id: $floor_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a floor plan by ID
#
# GET /networks/{networkId}/floorPlans/{floorPlanId}
# Returns: record
# operationId: getNetworkFloorPlan
export def "get-network-floor-plan" [
  network_id: string
  floor_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/floorPlans/{floorPlanId}"
    path_params: [{name: networkId, var: network_id}, {name: floorPlanId, var: floor_plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, floor_plan_id: $floor_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a floor plan's geolocation and other meta data
#
# PUT /networks/{networkId}/floorPlans/{floorPlanId}
# Returns: record
# operationId: updateNetworkFloorPlan
export def "update-network-floor-plan" [
  network_id: string
  floor_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottom-left-corner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottom-right-corner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. If you want to change the geolocation data of your floor plan, either the 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  --image-contents: string # The file contents (a base 64 encoded string) of your new image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. If you upload a new image, and you do NOT specify any new geolocation fields ('center, 'topLeftCorner', etc), the floor plan will be recentered with no rotation in order to maintain the aspect ratio of your new image. (format: byte)
  --name: string # The name of your floor plan.
  --top-left-corner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --top-right-corner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/floorPlans/{floorPlanId}"
    path_params: [{name: networkId, var: network_id}, {name: floorPlanId, var: floor_plan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bottomLeftCorner, var: bottom_left_corner}, {name: bottomRightCorner, var: bottom_right_corner}, {name: center, var: center}, {name: imageContents, var: image_contents}, {name: name, var: name}, {name: topLeftCorner, var: top_left_corner}, {name: topRightCorner, var: top_right_corner}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, floor_plan_id: $floor_plan_id, bottom_left_corner: $bottom_left_corner, bottom_right_corner: $bottom_right_corner, center: $center, image_contents: $image_contents, name: $name, top_left_corner: $top_left_corner, top_right_corner: $top_right_corner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the L3 firewall rules for an MX network
#
# GET /networks/{networkId}/l3FirewallRules
# Returns: list<record>
# operationId: getNetworkL3FirewallRules
export def "get-network-l3-firewall-rules" [
  network_id: string
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
    path: "/networks/{networkId}/l3FirewallRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the L3 firewall rules of an MX network
#
# PUT /networks/{networkId}/l3FirewallRules
# Returns: list<record>
# operationId: updateNetworkL3FirewallRules
export def "update-network-l3-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/l3FirewallRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}, {name: syslogDefaultRule, var: syslog_default_rule}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules, syslog_default_rule: $syslog_default_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the MX L7 firewall rules for an MX network
#
# GET /networks/{networkId}/l7FirewallRules
# Returns: record
# operationId: getNetworkL7FirewallRules
export def "get-network-l7-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/l7FirewallRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the MX L7 firewall rules for an MX network
#
# PUT /networks/{networkId}/l7FirewallRules
# Returns: record
# operationId: updateNetworkL7FirewallRules
export def "update-network-l7-firewall-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the MX L7 firewall rules — item shape: {policy?: "deny", type?: "application"|"applicationCategory"|"host"|"ipRange"|"port", value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/l7FirewallRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the L7 firewall application categories and their associated applications for an MX network
#
# GET /networks/{networkId}/l7FirewallRules/applicationCategories
# Returns: record
# operationId: getNetworkL7FirewallRulesApplicationCategories
export def "get-network-l7-firewall-rules-application-categories" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/l7FirewallRules/applicationCategories"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Aggregated latency info for this network
#
# GET /networks/{networkId}/latencyStats
# Returns: record
# operationId: getNetworkLatencyStats
export def "get-network-latency-stats" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/latencyStats"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: band, var: band}, {name: ssid, var: ssid}, {name: vlan, var: vlan}, {name: apTag, var: ap_tag}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, band: $band, ssid: $ssid, vlan: $vlan, ap_tag: $ap_tag, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the splash or RADIUS users configured under Meraki Authentication for a network
#
# GET /networks/{networkId}/merakiAuthUsers
# Returns: list<record>
# operationId: getNetworkMerakiAuthUsers
export def "get-network-meraki-auth-users" [
  network_id: string
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
    path: "/networks/{networkId}/merakiAuthUsers"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the Meraki Auth splash or RADIUS user
#
# GET /networks/{networkId}/merakiAuthUsers/{merakiAuthUserId}
# Returns: record
# operationId: getNetworkMerakiAuthUser
export def "get-network-meraki-auth-user" [
  network_id: string
  meraki_auth_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/merakiAuthUsers/{merakiAuthUserId}"
    path_params: [{name: networkId, var: network_id}, {name: merakiAuthUserId, var: meraki_auth_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, meraki_auth_user_id: $meraki_auth_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the 1:Many NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToManyNatRules
# Returns: record
# operationId: getNetworkOneToManyNatRules
export def "get-network-one-to-many-nat-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/oneToManyNatRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the 1:Many NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToManyNatRules
# Returns: record
# operationId: updateNetworkOneToManyNatRules
export def "update-network-one-to-many-nat-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of 1:Many nat rules — item shape: {portRules: list, publicIp: string, uplink: "internet1"|"internet2"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/oneToManyNatRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the 1:1 NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToOneNatRules
# Returns: record
# operationId: getNetworkOneToOneNatRules
export def "get-network-one-to-one-nat-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/oneToOneNatRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the 1:1 NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToOneNatRules
# Returns: record
# operationId: updateNetworkOneToOneNatRules
export def "update-network-one-to-one-nat-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of 1:1 nat rules — item shape: {allowedInbound?: list, lanIp: string, name?: string, publicIp?: string, uplink?: "internet1"|"internet2"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/oneToOneNatRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the keys required to access Personally Identifiable Information (PII) for a given identifier
#
# GET /networks/{networkId}/pii/piiKeys
# Returns: record
# operationId: getNetworkPiiPiiKeys
export def "get-network-pii-pii-keys" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/pii/piiKeys"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: username, var: username}, {name: email, var: email}, {name: mac, var: mac}, {name: serial, var: serial}, {name: imei, var: imei}, {name: bluetoothMac, var: bluetooth_mac}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, username: $username, email: $email, mac: $mac, serial: $serial, imei: $imei, bluetooth_mac: $bluetooth_mac
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the PII requests for this network or organization
#
# GET /networks/{networkId}/pii/requests
# Returns: list<record>
# operationId: getNetworkPiiRequests
export def "get-network-pii-requests" [
  network_id: string
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
    path: "/networks/{networkId}/pii/requests"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new delete or restrict processing PII request
#
# POST /networks/{networkId}/pii/requests
# Returns: record
# operationId: createNetworkPiiRequest
export def "create-network-pii-request" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasets: list<string> # The datasets related to the provided key that should be deleted. Only applies to "delete" requests. The value "all" will be expanded to all datasets applicable to this type. The datasets by applicable to each type are: mac (usage, events, traffic), email (users, loginAttempts), username (users, loginAttempts), bluetoothMac (client, connectivity), smDeviceId (device), smUserId (user)
  --email: string # The email of a network user account. Only applies to "delete" requests.
  --mac: string # The MAC of a network client device. Applies to both "restrict processing" and "delete" requests.
  --sm-device-id: string # The sm_device_id of a Systems Manager device. The only way to "restrict processing" or "delete" a Systems Manager device. Must include "device" in the dataset for a "delete" request to destroy the device.
  --sm-user-id: string # The sm_user_id of a Systems Manager user. The only way to "restrict processing" or "delete" a Systems Manager user. Must include "user" in the dataset for a "delete" request to destroy the user.
  --type: string@type-completer # One of "delete" or "restrict processing"
  --username: string # The username of a network log in. Only applies to "delete" requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/pii/requests"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasets, var: datasets}, {name: email, var: email}, {name: mac, var: mac}, {name: smDeviceId, var: sm_device_id}, {name: smUserId, var: sm_user_id}, {name: type, var: type}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, datasets: $datasets, email: $email, mac: $mac, sm_device_id: $sm_device_id, sm_user_id: $sm_user_id, type: $type, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a restrict processing PII request
#
# DELETE /networks/{networkId}/pii/requests/{requestId}
# operationId: deleteNetworkPiiRequest
export def "delete-network-pii-request" [
  network_id: string
  request_id: string
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
    path: "/networks/{networkId}/pii/requests/{requestId}"
    path_params: [{name: networkId, var: network_id}, {name: requestId, var: request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a PII request
#
# GET /networks/{networkId}/pii/requests/{requestId}
# Returns: record
# operationId: getNetworkPiiRequest
export def "get-network-pii-request" [
  network_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/pii/requests/{requestId}"
    path_params: [{name: networkId, var: network_id}, {name: requestId, var: request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager device ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smDevicesForKey
# Returns: record
# operationId: getNetworkPiiSmDevicesForKey
export def "get-network-pii-sm-devices-for-key" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/pii/smDevicesForKey"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: username, var: username}, {name: email, var: email}, {name: mac, var: mac}, {name: serial, var: serial}, {name: imei, var: imei}, {name: bluetoothMac, var: bluetooth_mac}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, username: $username, email: $email, mac: $mac, serial: $serial, imei: $imei, bluetooth_mac: $bluetooth_mac
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager owner ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smOwnersForKey
# Returns: record
# operationId: getNetworkPiiSmOwnersForKey
export def "get-network-pii-sm-owners-for-key" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/pii/smOwnersForKey"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: username, var: username}, {name: email, var: email}, {name: mac, var: mac}, {name: serial, var: serial}, {name: imei, var: imei}, {name: bluetoothMac, var: bluetooth_mac}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, username: $username, email: $email, mac: $mac, serial: $serial, imei: $imei, bluetooth_mac: $bluetooth_mac
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the port forwarding rules for an MX network
#
# GET /networks/{networkId}/portForwardingRules
# Returns: record
# operationId: getNetworkPortForwardingRules
export def "get-network-port-forwarding-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/portForwardingRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the port forwarding rules for an MX network
#
# PUT /networks/{networkId}/portForwardingRules
# Returns: record
# operationId: updateNetworkPortForwardingRules
export def "update-network-port-forwarding-rules" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of port forwarding params — item shape: {allowedIps: list<string>, lanIp: string, localPort: string, name?: string, protocol: "tcp"|"udp", publicPort: string, uplink?: "both"|"internet1"|"internet2"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/portForwardingRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all supported intrusion settings for an MX network
#
# GET /networks/{networkId}/security/intrusionSettings
# Returns: record
# operationId: getNetworkSecurityIntrusionSettings
export def "get-network-security-intrusion-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/security/intrusionSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the supported intrusion settings for an MX network
#
# PUT /networks/{networkId}/security/intrusionSettings
# Returns: record
# operationId: updateNetworkSecurityIntrusionSettings
export def "update-network-security-intrusion-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids-rulesets: string@ids-rulesets-completer # Set the detection ruleset 'connectivity'/'balanced'/'security' (optional - omitting will leave current config unchanged). Default value is 'balanced' if none currently saved
  --mode: string@mode-completer # Set mode to 'disabled'/'detection'/'prevention' (optional - omitting will leave current config unchanged)
  --protected-networks: record # Set the included/excluded networks from the intrusion engine (optional - omitting will leave current config unchanged). This is available only in 'passthrough' mode — shape: {excludedCidr?: list<string>, includedCidr?: list<string>, useDefault?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/security/intrusionSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: idsRulesets, var: ids_rulesets}, {name: mode, var: mode}, {name: protectedNetworks, var: protected_networks}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids_rulesets: $ids_rulesets, mode: $mode, protected_networks: $protected_networks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all supported malware settings for an MX network
#
# GET /networks/{networkId}/security/malwareSettings
# Returns: record
# operationId: getNetworkSecurityMalwareSettings
export def "get-network-security-malware-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/security/malwareSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the supported malware settings for an MX network
#
# PUT /networks/{networkId}/security/malwareSettings
# Returns: record
# operationId: updateNetworkSecurityMalwareSettings
export def "update-network-security-malware-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-files: list # The sha256 digests of files that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, sha256: string}
  --allowed-urls: list # The urls that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, url: string}
  mode: string@mode-completer-1 # Set mode to 'enabled' to enable malware prevention, otherwise 'disabled'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/security/malwareSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowedFiles, var: allowed_files}, {name: allowedUrls, var: allowed_urls}, {name: mode, var: mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, allowed_files: $allowed_files, allowed_urls: $allowed_urls, mode: $mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the security events (intrusion detection only) for a network
#
# GET /networks/{networkId}/securityEvents
# Returns: list<record>
# operationId: getNetworkSecurityEvents
export def "get-network-security-events" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. Data is gathered after the specified t0 value. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/securityEvents"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, t1: $t1, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the site-to-site VPN settings of a network
#
# GET /networks/{networkId}/siteToSiteVpn
# Returns: record
# operationId: getNetworkSiteToSiteVpn
export def "get-network-site-to-site-vpn" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/siteToSiteVpn"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the site-to-site VPN settings of a network
#
# PUT /networks/{networkId}/siteToSiteVpn
# Returns: record
# operationId: updateNetworkSiteToSiteVpn
export def "update-network-site-to-site-vpn" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hubs: list # The list of VPN hubs, in order of preference. In spoke mode, at least 1 hub is required. — item shape: {hubId: string, useDefaultRoute?: bool}
  mode: string@mode-completer-2 # The site-to-site VPN mode. Can be one of 'none', 'spoke' or 'hub'
  --subnets: list # The list of subnets and their VPN presence. — item shape: {localSubnet: string, useVpn?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/siteToSiteVpn"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hubs, var: hubs}, {name: mode, var: mode}, {name: subnets, var: subnets}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, hubs: $hubs, mode: $mode, subnets: $subnets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bypass activation lock attempt
#
# POST /networks/{networkId}/sm/bypassActivationLockAttempts
# Returns: record
# operationId: createNetworkSmBypassActivationLockAttempt
export def "create-network-sm-bypass-activation-lock-attempt" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string> # The ids of the devices to attempt activation lock bypass.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/sm/bypassActivationLockAttempts"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bypass activation lock attempt status
#
# GET /networks/{networkId}/sm/bypassActivationLockAttempts/{attemptId}
# Returns: record
# operationId: getNetworkSmBypassActivationLockAttempt
export def "get-network-sm-bypass-activation-lock-attempt" [
  network_id: string
  attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/sm/bypassActivationLockAttempts/{attemptId}"
    path_params: [{name: networkId, var: network_id}, {name: attemptId, var: attempt_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, attempt_id: $attempt_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the fields of a device
#
# PUT /networks/{networkId}/sm/device/fields
# Returns: record
# operationId: updateNetworkSmDeviceFields
export def "update-network-sm-device-fields" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_fields: record # The new fields of the device. Each field of this object is optional. — shape: {name?: string, notes?: string}
  --id: string # The id of the device to be modified.
  --serial: string # The serial of the device to be modified.
  --wifi-mac: string # The wifiMac of the device to be modified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/sm/device/fields"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceFields, var: device_fields}, {name: id, var: id}, {name: serial, var: serial}, {name: wifiMac, var: wifi_mac}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_fields: $device_fields, id: $id, serial: $serial, wifi_mac: $wifi_mac
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wipe a device
#
# PUT /networks/{networkId}/sm/device/wipe
# Returns: record
# operationId: wipeNetworkSmDevice
export def "wipe-network-sm-device" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The id of the device to be wiped.
  --pin: int # The pin number (a six digit value) for wiping a macOS device. Required only for macOS devices.
  --serial: string # The serial of the device to be wiped.
  --wifi-mac: string # The wifiMac of the device to be wiped.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/sm/device/wipe"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: pin, var: pin}, {name: serial, var: serial}, {name: wifiMac, var: wifi_mac}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, id: $id, pin: $pin, serial: $serial, wifi_mac: $wifi_mac
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh the details of a device
#
# POST /networks/{networkId}/sm/device/{deviceId}/refreshDetails
# operationId: refreshNetworkSmDeviceDetails
export def "refresh-network-sm-device-details" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/device/{deviceId}/refreshDetails"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the devices enrolled in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/devices
# Returns: record
# operationId: getNetworkSmDevices
export def "get-network-sm-devices" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Additional fields that will be displayed for each device. Multiple fields can be passed in as comma separated values. The default fields are: id, name, tags, ssid, wifiMac, osName, systemModel, uuid, and serialNumber. The additional fields are: ip, systemType, availableDeviceCapacity, kioskAppName, biosVersion, lastConnected, missingAppsCount, userSuppliedAddress, location, lastUser, ownerEmail, ownerUsername, publicIp, phoneNumber, diskInfoJson, deviceCapacity, isManaged, hadMdm, isSupervised, meid, imei, iccid, simCarrierNetwork, cellularDataUsed, isHotspotEnabled, createdAt, batteryEstCharge, quarantined, avName, avRunning, asName, fwName, isRooted, loginRequired, screenLockEnabled, screenLockDelay, autoLoginDisabled, autoTags, hasMdm, hasDesktopAgent, diskEncryptionEnabled, hardwareEncryptionCaps, passCodeLock, usesHardwareKeystore, and androidSecurityPatchVersion.
  --wifi-macs: string # Filter devices by wifi mac(s). Multiple wifi macs can be passed in as comma separated values.
  --serials: string # Filter devices by serial(s). Multiple serials can be passed in as comma separated values.
  --ids: string # Filter devices by id(s). Multiple ids can be passed in as comma separated values.
  --scope: string # Specify a scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags as comma separated values.
  --batch-size: int # Number of devices to return, 1000 is the default as well as the max.
  --batch-token: string # If the network has more devices than the batch size, a batch token will be returned as a part of the device list. To see the remainder of the devices, pass in the batchToken as a parameter in the next request. Requests made with the batchToken do not require additional parameters as the batchToken includes the parameters passed in with the original request. Additional parameters passed in with the batchToken will be ignored.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/devices"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: fields, var: fields}, {name: wifiMacs, var: wifi_macs}, {name: serials, var: serials}, {name: ids, var: ids}, {name: scope, var: scope}, {name: batchSize, var: batch_size}, {name: batchToken, var: batch_token}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, fields: $fields, wifi_macs: $wifi_macs, serials: $serials, ids: $ids, scope: $scope, batch_size: $batch_size, batch_token: $batch_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force check-in a set of devices
#
# PUT /networks/{networkId}/sm/devices/checkin
# Returns: record
# operationId: checkinNetworkSmDevices
export def "checkin-network-sm-devices" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be checked-in.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be checked-in.
  --serials: string # The serials of the devices to be checked-in.
  --wifi-macs: string # The wifiMacs of the devices to be checked-in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/sm/devices/checkin"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}, {name: scope, var: scope}, {name: serials, var: serials}, {name: wifiMacs, var: wifi_macs}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids: $ids, scope: $scope, serials: $serials, wifi_macs: $wifi_macs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add, delete, or update the tags of a set of devices
#
# PUT /networks/{networkId}/sm/devices/tags
# Returns: record
# operationId: updateNetworkSmDevicesTags
export def "update-network-sm-devices-tags" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be modified.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be modified.
  --serials: string # The serials of the devices to be modified.
  tags: string # The tags to be added, deleted, or updated.
  update_action: string # One of add, delete, or update. Only devices that have been modified will be returned.
  --wifi-macs: string # The wifiMacs of the devices to be modified.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/sm/devices/tags"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}, {name: scope, var: scope}, {name: serials, var: serials}, {name: tags, var: tags}, {name: updateAction, var: update_action}, {name: wifiMacs, var: wifi_macs}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids: $ids, scope: $scope, serials: $serials, tags: $tags, update_action: $update_action, wifi_macs: $wifi_macs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unenroll a device
#
# POST /networks/{networkId}/sm/devices/{deviceId}/unenroll
# Returns: record
# operationId: unenrollNetworkSmDevice
export def "unenroll-network-sm-device" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/sm/devices/{deviceId}/unenroll"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the profiles in the network
#
# GET /networks/{networkId}/sm/profiles
# Returns: record
# operationId: getNetworkSmProfiles
export def "get-network-sm-profiles" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/sm/profiles"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the target groups in this network
#
# GET /networks/{networkId}/sm/targetGroups
# Returns: list<record>
# operationId: getNetworkSmTargetGroups
export def "get-network-sm-target-groups" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-details: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/targetGroups"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: withDetails, var: with_details}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, with_details: $with_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a target group
#
# POST /networks/{networkId}/sm/targetGroups
# Returns: record
# operationId: createNetworkSmTargetGroup
export def "create-network-sm-target-group" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this target group
  --scope: string # The scope and tag options of the target group. Comma separated values beginning with one of withAny, withAll, withoutAny, withoutAll, all, none, followed by tags. Default to none if empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/sm/targetGroups"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, name: $name, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a target group from a network
#
# DELETE /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: deleteNetworkSmTargetGroup
export def "delete-network-sm-target-group" [
  network_id: string
  target_group_id: string
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
    path: "/networks/{networkId}/sm/targetGroups/{targetGroupId}"
    path_params: [{name: networkId, var: network_id}, {name: targetGroupId, var: target_group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, target_group_id: $target_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a target group
#
# GET /networks/{networkId}/sm/targetGroups/{targetGroupId}
# Returns: record
# operationId: getNetworkSmTargetGroup
export def "get-network-sm-target-group" [
  network_id: string
  target_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-details: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/targetGroups/{targetGroupId}"
    path_params: [{name: networkId, var: network_id}, {name: targetGroupId, var: target_group_id}]
    query: [{name: withDetails, var: with_details}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, target_group_id: $target_group_id, with_details: $with_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a target group
#
# PUT /networks/{networkId}/sm/targetGroups/{targetGroupId}
# Returns: record
# operationId: updateNetworkSmTargetGroup
export def "update-network-sm-target-group" [
  network_id: string
  target_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this target group
  --scope: string # The scope and tag options of the target group. Comma separated values beginning with one of withAny, withAll, withoutAny, withoutAll, all, none, followed by tags. Default to none if empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/sm/targetGroups/{targetGroupId}"
    path_params: [{name: networkId, var: network_id}, {name: targetGroupId, var: target_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, target_group_id: $target_group_id, name: $name, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the profiles associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/deviceProfiles
# Returns: list<record>
# operationId: getNetworkSmUserDeviceProfiles
export def "get-network-sm-user-device-profiles" [
  network_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/user/{userId}/deviceProfiles"
    path_params: [{name: networkId, var: network_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of softwares associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/softwares
# Returns: list<record>
# operationId: getNetworkSmUserSoftwares
export def "get-network-sm-user-softwares" [
  network_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/user/{userId}/softwares"
    path_params: [{name: networkId, var: network_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the owners in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/users
# Returns: list<record>
# operationId: getNetworkSmUsers
export def "get-network-sm-users" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Filter users by id(s). Multiple ids can be passed in as comma separated values.
  --usernames: string # Filter users by username(s). Multiple usernames can be passed in as comma separated values.
  --emails: string # Filter users by email(s). Multiple emails can be passed in as comma separated values.
  --scope: string # Specifiy a scope (one of all, none, withAny, withAll, withoutAny, withoutAll) and a set of tags as comma separated values.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/sm/users"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: ids, var: ids}, {name: usernames, var: usernames}, {name: emails, var: emails}, {name: scope, var: scope}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids: $ids, usernames: $usernames, emails: $emails, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the client's daily cellular data usage history
#
# GET /networks/{networkId}/sm/{deviceId}/cellularUsageHistory
# Returns: list<record>
# operationId: getNetworkSmCellularUsageHistory
export def "get-network-sm-cellular-usage-history" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/cellularUsageHistory"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the certs on a device
#
# GET /networks/{networkId}/sm/{deviceId}/certs
# Returns: list<record>
# operationId: getNetworkSmCerts
export def "get-network-sm-certs" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/certs"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the profiles associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/deviceProfiles
# Returns: list<record>
# operationId: getNetworkSmDeviceProfiles
export def "get-network-sm-device-profiles" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/deviceProfiles"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the network adapters of a device
#
# GET /networks/{networkId}/sm/{deviceId}/networkAdapters
# Returns: list<record>
# operationId: getNetworkSmNetworkAdapters
export def "get-network-sm-network-adapters" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/networkAdapters"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the restrictions on a device
#
# GET /networks/{networkId}/sm/{deviceId}/restrictions
# Returns: list<record>
# operationId: getNetworkSmRestrictions
export def "get-network-sm-restrictions" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/restrictions"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the security centers on a device
#
# GET /networks/{networkId}/sm/{deviceId}/securityCenters
# Returns: list<record>
# operationId: getNetworkSmSecurityCenters
export def "get-network-sm-security-centers" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/securityCenters"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of softwares associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/softwares
# Returns: list<record>
# operationId: getNetworkSmSoftwares
export def "get-network-sm-softwares" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/softwares"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the saved SSID names on a device
#
# GET /networks/{networkId}/sm/{deviceId}/wlanLists
# Returns: list<record>
# operationId: getNetworkSmWlanLists
export def "get-network-sm-wlan-lists" [
  network_id: string
  device_id: string
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
    path: "/networks/{networkId}/sm/{deviceId}/wlanLists"
    path_params: [{name: networkId, var: network_id}, {name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the SNMP settings for a network
#
# GET /networks/{networkId}/snmpSettings
# Returns: record
# operationId: getNetworkSnmpSettings
export def "get-network-snmp-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/snmpSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the splash login attempts for a network
#
# GET /networks/{networkId}/splashLoginAttempts
# Returns: list<record>
# operationId: getNetworkSplashLoginAttempts
export def "get-network-splash-login-attempts" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssid-number: int@ssid-number-completer # Only return the login attempts for the specified SSID
  --login-identifier: string # The username, email, or phone number used during login
  --timespan: int # The timespan, in seconds, for the login attempts. The period will be from [timespan] seconds ago until now. The maximum timespan is 3 months
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/splashLoginAttempts"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: ssidNumber, var: ssid_number}, {name: loginIdentifier, var: login_identifier}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ssid_number: $ssid_number, login_identifier: $login_identifier, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Split a combined network into individual networks for each type of device
#
# POST /networks/{networkId}/split
# Returns: record
# operationId: splitNetwork
export def "split-network" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/split"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the SSIDs in a network
#
# GET /networks/{networkId}/ssids
# Returns: list<record>
# operationId: getNetworkSsids
export def "get-network-ssids" [
  network_id: string
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
    path: "/networks/{networkId}/ssids"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a single SSID
#
# GET /networks/{networkId}/ssids/{number}
# Returns: record
# operationId: getNetworkSsid
export def "get-network-ssid" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/ssids/{number}"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attributes of an SSID
#
# PUT /networks/{networkId}/ssids/{number}
# Returns: record
# operationId: updateNetworkSsid
export def "update-network-ssid" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-tags-and-vlan-ids: list # The list of tags and VLAN IDs used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming' — item shape: {tags?: string, vlanId?: int}
  --auth-mode: string@auth-mode-completer # The association control method for the SSID ('open', 'open-enhanced', 'psk', 'open-with-radius', 'open-with-nac', '8021x-meraki', '8021x-nac', '8021x-radius', '8021x-google', '8021x-localradius', 'ipsk-with-radius' or 'ipsk-without-radius')
  --availability-tags: list<string> # Accepts a list of tags for this SSID. If availableOnAllAps is false, then the SSID will only be broadcast by APs with tags matching any of the tags in this list.
  --available-on-all-aps: oneof<nothing, bool> # Boolean indicating whether all APs should broadcast the SSID or if it should be restricted to APs matching any availability tags. Can only be false if the SSID has availability tags.
  --band-selection: string # The client-serving radio frequencies of this SSID in the default indoor RF profile. ('Dual band operation', '5 GHz band only' or 'Dual band operation with Band Steering')
  --concentrator-network-id: string # The concentrator to use when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'.
  --default-vlan-id: int # The default VLAN ID used for 'all other APs'. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --disassociate-clients-on-vpn-failover: oneof<nothing, bool> # Disassociate clients when 'VPN' concentrator failover occurs in order to trigger clients to re-associate and generate new DHCP requests. This param is only valid if ipAssignmentMode is 'VPN'.
  --enabled: oneof<nothing, bool> # Whether or not the SSID is enabled
  --encryption-mode: string@encryption-mode-completer # The psk encryption mode for the SSID ('wep' or 'wpa'). This param is only valid if the authMode is 'psk'
  --enterprise-admin-access: string@enterprise-admin-access-completer # Whether or not an SSID is accessible by 'enterprise' administrators ('access disabled' or 'access enabled')
  --ip-assignment-mode: string # The client IP assignment mode ('NAT mode', 'Bridge mode', 'Layer 3 roaming', 'Ethernet over GRE', 'Layer 3 roaming with a concentrator' or 'VPN')
  --lan-isolation-enabled: oneof<nothing, bool> # Boolean indicating whether Layer 2 LAN isolation should be enabled or disabled. Only configurable when ipAssignmentMode is 'Bridge mode'.
  --min-bitrate: float # The minimum bitrate in Mbps of this SSID in the default indoor RF profile. ('1', '2', '5.5', '6', '9', '11', '12', '18', '24', '36', '48' or '54') (format: float)
  --name: string # The name of the SSID
  --per-client-bandwidth-limit-down: int # The download bandwidth limit in Kbps. (0 represents no limit.)
  --per-client-bandwidth-limit-up: int # The upload bandwidth limit in Kbps. (0 represents no limit.)
  --psk: string # The passkey for the SSID. This param is only valid if the authMode is 'psk'
  --radius-accounting-enabled: oneof<nothing, bool> # Whether or not RADIUS accounting is enabled. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'
  --radius-accounting-servers: list # The RADIUS accounting 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' and radiusAccountingEnabled is 'true' — item shape: {host: string, port?: int, secret?: string}
  --radius-attribute-for-group-policies: string # Specify the RADIUS attribute used to look up group policies ('Filter-Id', 'Reply-Message', 'Airespace-ACL-Name' or 'Aruba-User-Role'). Access points must receive this attribute in the RADIUS Access-Accept message
  --radius-coa-enabled: oneof<nothing, bool> # If true, Meraki devices will act as a RADIUS Dynamic Authorization Server and will respond to RADIUS Change-of-Authorization and Disconnect messages sent by the RADIUS server.
  --radius-failover-policy: string@radius-failover-policy-completer # This policy determines how authentication requests should be handled in the event that all of the configured RADIUS servers are unreachable ('Deny access' or 'Allow access')
  --radius-load-balancing-policy: string@radius-load-balancing-policy-completer # This policy determines which RADIUS server will be contacted first in an authentication attempt and the ordering of any necessary retry attempts ('Strict priority order' or 'Round robin')
  --radius-override: oneof<nothing, bool> # If true, the RADIUS response can override VLAN tag. This is not valid when ipAssignmentMode is 'NAT mode'.
  --radius-servers: list # The RADIUS 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' — item shape: {host: string, port?: int, secret?: string}
  --secondary-concentrator-network-id: string # The secondary concentrator to use when the ipAssignmentMode is 'VPN'. If configured, the APs will switch to using this concentrator if the primary concentrator is unreachable. This param is optional. ('disabled' represents no secondary concentrator.)
  --splash-page: string@splash-page-completer # The type of splash page for the SSID ('None', 'Click-through splash page', 'Billing', 'Password-protected with Meraki RADIUS', 'Password-protected with custom RADIUS', 'Password-protected with Active Directory', 'Password-protected with LDAP', 'SMS authentication', 'Systems Manager Sentry', 'Facebook Wi-Fi', 'Google OAuth', 'Sponsored guest', 'Cisco ISE' or 'Google Apps domain'). This attribute is not supported for template children.
  --use-vlan-tagging: oneof<nothing, bool> # Whether or not traffic should be directed to use specific VLANs. This param is only valid if the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --visible: oneof<nothing, bool> # Boolean indicating whether APs should advertise or hide this SSID. APs will only broadcast this SSID if set to true
  --vlan-id: int # The VLAN ID used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'
  --walled-garden-enabled: oneof<nothing, bool> # Allow access to a configurable list of IP ranges, which users may access prior to sign-on.
  --walled-garden-ranges: string # Specify your walled garden by entering space-separated addresses, ranges using CIDR notation, domain names, and domain wildcards (e.g. 192.168.1.1/24 192.168.37.10/32 www.yahoo.com *.google.com). Meraki's splash page is automatically included in your walled garden.
  --wpa-encryption-mode: string@wpa-encryption-mode-completer # The types of WPA encryption. ('WPA1 only', 'WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode' or 'WPA3 only')
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/ssids/{number}"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: apTagsAndVlanIds, var: ap_tags_and_vlan_ids}, {name: authMode, var: auth_mode}, {name: availabilityTags, var: availability_tags}, {name: availableOnAllAps, var: available_on_all_aps}, {name: bandSelection, var: band_selection}, {name: concentratorNetworkId, var: concentrator_network_id}, {name: defaultVlanId, var: default_vlan_id}, {name: disassociateClientsOnVpnFailover, var: disassociate_clients_on_vpn_failover}, {name: enabled, var: enabled}, {name: encryptionMode, var: encryption_mode}, {name: enterpriseAdminAccess, var: enterprise_admin_access}, {name: ipAssignmentMode, var: ip_assignment_mode}, {name: lanIsolationEnabled, var: lan_isolation_enabled}, {name: minBitrate, var: min_bitrate}, {name: name, var: name}, {name: perClientBandwidthLimitDown, var: per_client_bandwidth_limit_down}, {name: perClientBandwidthLimitUp, var: per_client_bandwidth_limit_up}, {name: psk, var: psk}, {name: radiusAccountingEnabled, var: radius_accounting_enabled}, {name: radiusAccountingServers, var: radius_accounting_servers}, {name: radiusAttributeForGroupPolicies, var: radius_attribute_for_group_policies}, {name: radiusCoaEnabled, var: radius_coa_enabled}, {name: radiusFailoverPolicy, var: radius_failover_policy}, {name: radiusLoadBalancingPolicy, var: radius_load_balancing_policy}, {name: radiusOverride, var: radius_override}, {name: radiusServers, var: radius_servers}, {name: secondaryConcentratorNetworkId, var: secondary_concentrator_network_id}, {name: splashPage, var: splash_page}, {name: useVlanTagging, var: use_vlan_tagging}, {name: visible, var: visible}, {name: vlanId, var: vlan_id}, {name: walledGardenEnabled, var: walled_garden_enabled}, {name: walledGardenRanges, var: walled_garden_ranges}, {name: wpaEncryptionMode, var: wpa_encryption_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number, ap_tags_and_vlan_ids: $ap_tags_and_vlan_ids, auth_mode: $auth_mode, availability_tags: $availability_tags, available_on_all_aps: $available_on_all_aps, band_selection: $band_selection, concentrator_network_id: $concentrator_network_id, default_vlan_id: $default_vlan_id, disassociate_clients_on_vpn_failover: $disassociate_clients_on_vpn_failover, enabled: $enabled, encryption_mode: $encryption_mode, enterprise_admin_access: $enterprise_admin_access, ip_assignment_mode: $ip_assignment_mode, lan_isolation_enabled: $lan_isolation_enabled, min_bitrate: $min_bitrate, name: $name, per_client_bandwidth_limit_down: $per_client_bandwidth_limit_down, per_client_bandwidth_limit_up: $per_client_bandwidth_limit_up, psk: $psk, radius_accounting_enabled: $radius_accounting_enabled, radius_accounting_servers: $radius_accounting_servers, radius_attribute_for_group_policies: $radius_attribute_for_group_policies, radius_coa_enabled: $radius_coa_enabled, radius_failover_policy: $radius_failover_policy, radius_load_balancing_policy: $radius_load_balancing_policy, radius_override: $radius_override, radius_servers: $radius_servers, secondary_concentrator_network_id: $secondary_concentrator_network_id, splash_page: $splash_page, use_vlan_tagging: $use_vlan_tagging, visible: $visible, vlan_id: $vlan_id, walled_garden_enabled: $walled_garden_enabled, walled_garden_ranges: $walled_garden_ranges, wpa_encryption_mode: $wpa_encryption_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the L3 firewall rules for an SSID on an MR network
#
# GET /networks/{networkId}/ssids/{number}/l3FirewallRules
# Returns: list<record>
# operationId: getNetworkSsidL3FirewallRules
export def "get-network-ssid-l3-firewall-rules" [
  network_id: string
  number: string
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
    path: "/networks/{networkId}/ssids/{number}/l3FirewallRules"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the L3 firewall rules of an SSID on an MR network
#
# PUT /networks/{networkId}/ssids/{number}/l3FirewallRules
# Returns: list<record>
# operationId: updateNetworkSsidL3FirewallRules
export def "update-network-ssid-l3-firewall-rules" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-lan-access: oneof<nothing, bool> # Allow wireless client access to local LAN (boolean value - true allows access and false denies access) (optional)
  --rules: list # An ordered array of the firewall rules for this SSID (not including the local LAN access rule or the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp"}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/ssids/{number}/l3FirewallRules"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowLanAccess, var: allow_lan_access}, {name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number, allow_lan_access: $allow_lan_access, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display the splash page settings for the given SSID
#
# GET /networks/{networkId}/ssids/{number}/splashSettings
# Returns: record
# operationId: getNetworkSsidSplashSettings
export def "get-network-ssid-splash-settings" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/ssids/{number}/splashSettings"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the splash page settings for the given SSID
#
# PUT /networks/{networkId}/ssids/{number}/splashSettings
# Returns: record
# operationId: updateNetworkSsidSplashSettings
export def "update-network-ssid-splash-settings" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --splash-url: string # [optional] The custom splash URL of the click-through splash page. Note that the URL can be configured without necessarily being used. In order to enable the custom URL, see 'useSplashUrl'
  --use-splash-url: oneof<nothing, bool> # [optional] Boolean indicating whether the user will be redirected to the custom splash url. A custom splash URL must be set if this is true. Note that depending on your SSID's access control settings, it may not be possible to use the custom splash URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/ssids/{number}/splashSettings"
    path_params: [{name: networkId, var: network_id}, {name: number, var: number}]
    body: {content_type: "application/json", kind: json, fields: [{name: splashUrl, var: splash_url}, {name: useSplashUrl, var: use_splash_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, number: $number, splash_url: $splash_url, use_splash_url: $use_splash_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the static routes for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes
# Returns: list<record>
# operationId: getNetworkStaticRoutes
export def "get-network-static-routes" [
  network_id: string
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
    path: "/networks/{networkId}/staticRoutes"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a static route for an MX or teleworker network
#
# POST /networks/{networkId}/staticRoutes
# Returns: record
# operationId: createNetworkStaticRoute
export def "create-network-static-route" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  gateway_ip: string # The gateway IP (next hop) of the static route
  name: string # The name of the new static route
  subnet: string # The subnet of the static route
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/staticRoutes"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: gatewayIp, var: gateway_ip}, {name: name, var: name}, {name: subnet, var: subnet}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, gateway_ip: $gateway_ip, name: $name, subnet: $subnet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a static route from an MX or teleworker network
#
# DELETE /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: deleteNetworkStaticRoute
export def "delete-network-static-route" [
  network_id: string
  static_route_id: string
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
    path: "/networks/{networkId}/staticRoutes/{staticRouteId}"
    path_params: [{name: networkId, var: network_id}, {name: staticRouteId, var: static_route_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, static_route_id: $static_route_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a static route for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes/{staticRouteId}
# Returns: record
# operationId: getNetworkStaticRoute
export def "get-network-static-route" [
  network_id: string
  static_route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/staticRoutes/{staticRouteId}"
    path_params: [{name: networkId, var: network_id}, {name: staticRouteId, var: static_route_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, static_route_id: $static_route_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a static route for an MX or teleworker network
#
# PUT /networks/{networkId}/staticRoutes/{staticRouteId}
# Returns: record
# operationId: updateNetworkStaticRoute
export def "update-network-static-route" [
  network_id: string
  static_route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # The enabled state of the static route
  --fixed-ip-assignments: record # The DHCP fixed IP assignments on the static route. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --gateway-ip: string # The gateway IP (next hop) of the static route
  --name: string # The name of the static route
  --reserved-ip-ranges: list # The DHCP reserved IP ranges on the static route — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the static route
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/staticRoutes/{staticRouteId}"
    path_params: [{name: networkId, var: network_id}, {name: staticRouteId, var: static_route_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: fixedIpAssignments, var: fixed_ip_assignments}, {name: gatewayIp, var: gateway_ip}, {name: name, var: name}, {name: reservedIpRanges, var: reserved_ip_ranges}, {name: subnet, var: subnet}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, static_route_id: $static_route_id, enabled: $enabled, fixed_ip_assignments: $fixed_ip_assignments, gateway_ip: $gateway_ip, name: $name, reserved_ip_ranges: $reserved_ip_ranges, subnet: $subnet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Swap MX primary and warm spare appliances
#
# POST /networks/{networkId}/swapWarmSpare
# Returns: record
# operationId: swapNetworkWarmSpare
export def "swap-network-warm-spare" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/swapWarmSpare"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List link aggregation groups
#
# GET /networks/{networkId}/switch/linkAggregations
# Returns: list<record>
# operationId: getNetworkSwitchLinkAggregations
export def "get-network-switch-link-aggregations" [
  network_id: string
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
    path: "/networks/{networkId}/switch/linkAggregations"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a link aggregation group
#
# POST /networks/{networkId}/switch/linkAggregations
# Returns: record
# operationId: createNetworkSwitchLinkAggregation
export def "create-network-switch-link-aggregation" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-ports: list # Array of switch or stack ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switch-profile-ports: list # Array of switch profile ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switch/linkAggregations"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: switchPorts, var: switch_ports}, {name: switchProfilePorts, var: switch_profile_ports}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, switch_ports: $switch_ports, switch_profile_ports: $switch_profile_ports
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Split a link aggregation group into separate ports
#
# DELETE /networks/{networkId}/switch/linkAggregations/{linkAggregationId}
# operationId: deleteNetworkSwitchLinkAggregation
export def "delete-network-switch-link-aggregation" [
  network_id: string
  link_aggregation_id: string
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
    path: "/networks/{networkId}/switch/linkAggregations/{linkAggregationId}"
    path_params: [{name: networkId, var: network_id}, {name: linkAggregationId, var: link_aggregation_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, link_aggregation_id: $link_aggregation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a link aggregation group
#
# PUT /networks/{networkId}/switch/linkAggregations/{linkAggregationId}
# Returns: record
# operationId: updateNetworkSwitchLinkAggregation
export def "update-network-switch-link-aggregation" [
  network_id: string
  link_aggregation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-ports: list # Array of switch or stack ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switch-profile-ports: list # Array of switch profile ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/linkAggregations/{linkAggregationId}"
    path_params: [{name: networkId, var: network_id}, {name: linkAggregationId, var: link_aggregation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: switchPorts, var: switch_ports}, {name: switchProfilePorts, var: switch_profile_ports}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, link_aggregation_id: $link_aggregation_id, switch_ports: $switch_ports, switch_profile_ports: $switch_profile_ports
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List switch port schedules
#
# GET /networks/{networkId}/switch/portSchedules
# Returns: list<record>
# operationId: getNetworkSwitchPortSchedules
export def "get-network-switch-port-schedules" [
  network_id: string
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
    path: "/networks/{networkId}/switch/portSchedules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a switch port schedule
#
# POST /networks/{networkId}/switch/portSchedules
# Returns: record
# operationId: createNetworkSwitchPortSchedule
export def "create-network-switch-port-schedule" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for your port schedule. Required
  --port-schedule: record # The schedule for switch port scheduling. Schedules are applied to days of the week. When it's empty, default schedule with all days of a week are configured. Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switch/portSchedules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: portSchedule, var: port_schedule}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, name: $name, port_schedule: $port_schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a switch port schedule
#
# DELETE /networks/{networkId}/switch/portSchedules/{portScheduleId}
# operationId: deleteNetworkSwitchPortSchedule
export def "delete-network-switch-port-schedule" [
  network_id: string
  port_schedule_id: string
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
    path: "/networks/{networkId}/switch/portSchedules/{portScheduleId}"
    path_params: [{name: networkId, var: network_id}, {name: portScheduleId, var: port_schedule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, port_schedule_id: $port_schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a switch port schedule
#
# PUT /networks/{networkId}/switch/portSchedules/{portScheduleId}
# Returns: record
# operationId: updateNetworkSwitchPortSchedule
export def "update-network-switch-port-schedule" [
  network_id: string
  port_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for your port schedule.
  --port-schedule: record # The schedule for switch port scheduling. Schedules are applied to days of the week. When it's empty, default schedule with all days of a week are configured. Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/portSchedules/{portScheduleId}"
    path_params: [{name: networkId, var: network_id}, {name: portScheduleId, var: port_schedule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: portSchedule, var: port_schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, port_schedule_id: $port_schedule_id, name: $name, port_schedule: $port_schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the switch network settings
#
# GET /networks/{networkId}/switch/settings
# Returns: record
# operationId: getNetworkSwitchSettings
export def "get-network-switch-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update switch network settings
#
# PUT /networks/{networkId}/switch/settings
# Returns: record
# operationId: updateNetworkSwitchSettings
export def "update-network-switch-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --power-exceptions: list # Exceptions on a per switch basis to "useCombinedPower" — item shape: {powerType: "combined"|"redundant"|"useNetworkSetting", serial: string}
  --use-combined-power: oneof<nothing, bool> # The use Combined Power as the default behavior of secondary power supplies on supported devices.
  --vlan: int # Management VLAN
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: powerExceptions, var: power_exceptions}, {name: useCombinedPower, var: use_combined_power}, {name: vlan, var: vlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, power_exceptions: $power_exceptions, use_combined_power: $use_combined_power, vlan: $vlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the MTU configuration
#
# GET /networks/{networkId}/switch/settings/mtu
# Returns: record
# operationId: getNetworkSwitchSettingsMtu
export def "get-network-switch-settings-mtu" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings/mtu"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the MTU configuration
#
# PUT /networks/{networkId}/switch/settings/mtu
# Returns: record
# operationId: updateNetworkSwitchSettingsMtu
export def "update-network-switch-settings-mtu" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-mtu-size: int # MTU size for the entire network. Default value is 9578.
  --overrides: list # Override MTU size for individual switches or switch profiles. An empty array will clear overrides. — item shape: {mtuSize: int, switchProfiles?: list<string>, switches?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings/mtu"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultMtuSize, var: default_mtu_size}, {name: overrides, var: overrides}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, default_mtu_size: $default_mtu_size, overrides: $overrides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return multicast settings for a network
#
# GET /networks/{networkId}/switch/settings/multicast
# Returns: record
# operationId: getNetworkSwitchSettingsMulticast
export def "get-network-switch-settings-multicast" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings/multicast"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update multicast settings for a network
#
# PUT /networks/{networkId}/switch/settings/multicast
# Returns: record
# operationId: updateNetworkSwitchSettingsMulticast
export def "update-network-switch-settings-multicast" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-settings: record # Default multicast setting for entire network. IGMP snooping and Flood unknown multicast traffic settings are enabled by default. — shape: {floodUnknownMulticastTrafficEnabled?: bool, igmpSnoopingEnabled?: bool}
  --overrides: list # Array of paired switches/stacks/profiles and corresponding multicast settings. An empty array will clear the multicast settings. — item shape: {floodUnknownMulticastTrafficEnabled: bool, igmpSnoopingEnabled: bool, stacks?: list<string>, switchProfiles?: list<string>, switches?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings/multicast"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultSettings, var: default_settings}, {name: overrides, var: overrides}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, default_settings: $default_settings, overrides: $overrides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List quality of service rules
#
# GET /networks/{networkId}/switch/settings/qosRules
# Returns: list<record>
# operationId: getNetworkSwitchSettingsQosRules
export def "get-network-switch-settings-qos-rules" [
  network_id: string
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
    path: "/networks/{networkId}/switch/settings/qosRules"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a quality of service rule
#
# POST /networks/{networkId}/switch/settings/qosRules
# Returns: record
# operationId: createNetworkSwitchSettingsQosRule
export def "create-network-switch-settings-qos-rule" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag. Set this to -1 to trust incoming DSCP. Default value is 0
  --dst-port: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dst-port-range: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY"
  --src-port: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --src-port-range: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switch/settings/qosRules"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dscp, var: dscp}, {name: dstPort, var: dst_port}, {name: dstPortRange, var: dst_port_range}, {name: protocol, var: protocol}, {name: srcPort, var: src_port}, {name: srcPortRange, var: src_port_range}, {name: vlan, var: vlan}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, dscp: $dscp, dst_port: $dst_port, dst_port_range: $dst_port_range, protocol: $protocol, src_port: $src_port, src_port_range: $src_port_range, vlan: $vlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the quality of service rule IDs by order in which they will be processed by the switch
#
# GET /networks/{networkId}/switch/settings/qosRules/order
# Returns: record
# operationId: getNetworkSwitchSettingsQosRulesOrder
export def "get-network-switch-settings-qos-rules-order" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings/qosRules/order"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the order in which the rules should be processed by the switch
#
# PUT /networks/{networkId}/switch/settings/qosRules/order
# Returns: record
# operationId: updateNetworkSwitchSettingsQosRulesOrder
export def "update-network-switch-settings-qos-rules-order" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rule_ids: list<string> # A list of quality of service rule IDs arranged in order in which they should be processed by the switch.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings/qosRules/order"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ruleIds, var: rule_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rule_ids: $rule_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a quality of service rule
#
# DELETE /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: deleteNetworkSwitchSettingsQosRule
export def "delete-network-switch-settings-qos-rule" [
  network_id: string
  qos_rule_id: string
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
    path: "/networks/{networkId}/switch/settings/qosRules/{qosRuleId}"
    path_params: [{name: networkId, var: network_id}, {name: qosRuleId, var: qos_rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, qos_rule_id: $qos_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a quality of service rule
#
# GET /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# Returns: record
# operationId: getNetworkSwitchSettingsQosRule
export def "get-network-switch-settings-qos-rule" [
  network_id: string
  qos_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings/qosRules/{qosRuleId}"
    path_params: [{name: networkId, var: network_id}, {name: qosRuleId, var: qos_rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, qos_rule_id: $qos_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a quality of service rule
#
# PUT /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# Returns: record
# operationId: updateNetworkSwitchSettingsQosRule
export def "update-network-switch-settings-qos-rule" [
  network_id: string
  qos_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag that should be assigned to incoming packet. Set this to -1 to trust incoming DSCP. Default value is 0.
  --dst-port: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dst-port-range: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY".
  --src-port: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --src-port-range: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings/qosRules/{qosRuleId}"
    path_params: [{name: networkId, var: network_id}, {name: qosRuleId, var: qos_rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dscp, var: dscp}, {name: dstPort, var: dst_port}, {name: dstPortRange, var: dst_port_range}, {name: protocol, var: protocol}, {name: srcPort, var: src_port}, {name: srcPortRange, var: src_port_range}, {name: vlan, var: vlan}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, qos_rule_id: $qos_rule_id, dscp: $dscp, dst_port: $dst_port, dst_port_range: $dst_port_range, protocol: $protocol, src_port: $src_port, src_port_range: $src_port_range, vlan: $vlan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the storm control configuration for a switch network
#
# GET /networks/{networkId}/switch/settings/stormControl
# Returns: record
# operationId: getNetworkSwitchSettingsStormControl
export def "get-network-switch-settings-storm-control" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switch/settings/stormControl"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the storm control configuration for a switch network
#
# PUT /networks/{networkId}/switch/settings/stormControl
# Returns: record
# operationId: updateNetworkSwitchSettingsStormControl
export def "update-network-switch-settings-storm-control" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcast-threshold: int # Percentage (1 to 99) of total available port bandwidth for broadcast traffic type. Default value 100 percent rate is to clear the configuration.
  --multicast-threshold: int # Percentage (1 to 99) of total available port bandwidth for multicast traffic type. Default value 100 percent rate is to clear the configuration.
  --unknown-unicast-threshold: int # Percentage (1 to 99) of total available port bandwidth for unknown unicast (dlf-destination lookup failure) traffic type. Default value 100 percent rate is to clear the configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/switch/settings/stormControl"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: broadcastThreshold, var: broadcast_threshold}, {name: multicastThreshold, var: multicast_threshold}, {name: unknownUnicastThreshold, var: unknown_unicast_threshold}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, broadcast_threshold: $broadcast_threshold, multicast_threshold: $multicast_threshold, unknown_unicast_threshold: $unknown_unicast_threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the switch stacks in a network
#
# GET /networks/{networkId}/switchStacks
# Returns: list<record>
# operationId: getNetworkSwitchStacks
export def "get-network-switch-stacks" [
  network_id: string
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
    path: "/networks/{networkId}/switchStacks"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a stack
#
# POST /networks/{networkId}/switchStacks
# Returns: record
# operationId: createNetworkSwitchStack
export def "create-network-switch-stack" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new stack
  serials: list<string> # An array of switch serials to be added into the new stack
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switchStacks"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: serials, var: serials}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, name: $name, serials: $serials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a stack
#
# DELETE /networks/{networkId}/switchStacks/{switchStackId}
# operationId: deleteNetworkSwitchStack
export def "delete-network-switch-stack" [
  network_id: string
  switch_stack_id: string
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
    path: "/networks/{networkId}/switchStacks/{switchStackId}"
    path_params: [{name: networkId, var: network_id}, {name: switchStackId, var: switch_stack_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, switch_stack_id: $switch_stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a switch stack
#
# GET /networks/{networkId}/switchStacks/{switchStackId}
# Returns: record
# operationId: getNetworkSwitchStack
export def "get-network-switch-stack" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/switchStacks/{switchStackId}"
    path_params: [{name: networkId, var: network_id}, {name: switchStackId, var: switch_stack_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, switch_stack_id: $switch_stack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a switch to a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/add
# Returns: record
# operationId: addNetworkSwitchStack
export def "add-network-switch-stack" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  serial: string # The serial of the switch to be added
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switchStacks/{switchStackId}/add"
    path_params: [{name: networkId, var: network_id}, {name: switchStackId, var: switch_stack_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: serial, var: serial}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, switch_stack_id: $switch_stack_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a switch from a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/remove
# Returns: record
# operationId: removeNetworkSwitchStack
export def "remove-network-switch-stack" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  serial: string # The serial of the switch to be removed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/switchStacks/{switchStackId}/remove"
    path_params: [{name: networkId, var: network_id}, {name: switchStackId, var: switch_stack_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: serial, var: serial}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, switch_stack_id: $switch_stack_id, serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the syslog servers for a network
#
# GET /networks/{networkId}/syslogServers
# Returns: list<record>
# operationId: getNetworkSyslogServers
export def "get-network-syslog-servers" [
  network_id: string
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
    path: "/networks/{networkId}/syslogServers"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the syslog servers for a network
#
# PUT /networks/{networkId}/syslogServers
# Returns: list<record>
# operationId: updateNetworkSyslogServers
export def "update-network-syslog-servers" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  servers: list # A list of the syslog servers for this network — item shape: {host: string, port: int, roles: list<string>}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/syslogServers"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: servers, var: servers}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, servers: $servers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the traffic analysis data for this network
#
# GET /networks/{networkId}/traffic
# Returns: list<record>
# operationId: getNetworkTraffic
export def "get-network-traffic" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 30 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 30 days. (format: float)
  --device-type: string@device-type-completer # Filter the data by device type: 'combined', 'wireless', 'switch' or 'appliance'. Defaults to 'combined'. When using 'combined', for each rule the data will come from the device type with the most usage.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/traffic"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: t0, var: t0}, {name: timespan, var: timespan}, {name: deviceType, var: device_type}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, t0: $t0, timespan: $timespan, device_type: $device_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unbind a network from a template.
#
# POST /networks/{networkId}/unbind
# operationId: unbindNetwork
export def "unbind-network" [
  network_id: string
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
    path: "/networks/{networkId}/unbind"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the uplink settings for your MX network.
#
# GET /networks/{networkId}/uplinkSettings
# Returns: record
# operationId: getNetworkUplinkSettings
export def "get-network-uplink-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/uplinkSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the uplink settings for your MX network.
#
# PUT /networks/{networkId}/uplinkSettings
# Returns: record
# operationId: updateNetworkUplinkSettings
export def "update-network-uplink-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bandwidth-limits: record # A mapping of uplinks to their bandwidth settings (be sure to check which uplinks are supported for your network) — shape: {cellular?: record, wan1?: record, wan2?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/uplinkSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bandwidthLimits, var: bandwidth_limits}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, bandwidth_limits: $bandwidth_limits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the VLANs for an MX network
#
# GET /networks/{networkId}/vlans
# Returns: list<record>
# operationId: getNetworkVlans
export def "get-network-vlans" [
  network_id: string
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
    path: "/networks/{networkId}/vlans"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a VLAN
#
# POST /networks/{networkId}/vlans
# Returns: record
# operationId: createNetworkVlan
export def "create-network-vlan" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  appliance_ip: string # The local IP of the appliance on the VLAN
  --group-policy-id: string # The id of the desired group policy to apply to the VLAN
  id: string # The VLAN ID of the new VLAN (must be between 1 and 4094)
  name: string # The name of the new VLAN
  subnet: string # The subnet of the VLAN
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/vlans"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applianceIp, var: appliance_ip}, {name: groupPolicyId, var: group_policy_id}, {name: id, var: id}, {name: name, var: name}, {name: subnet, var: subnet}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, appliance_ip: $appliance_ip, group_policy_id: $group_policy_id, id: $id, name: $name, subnet: $subnet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a VLAN from a network
#
# DELETE /networks/{networkId}/vlans/{vlanId}
# operationId: deleteNetworkVlan
export def "delete-network-vlan" [
  network_id: string
  vlan_id: string
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
    path: "/networks/{networkId}/vlans/{vlanId}"
    path_params: [{name: networkId, var: network_id}, {name: vlanId, var: vlan_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, vlan_id: $vlan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a VLAN
#
# GET /networks/{networkId}/vlans/{vlanId}
# Returns: record
# operationId: getNetworkVlan
export def "get-network-vlan" [
  network_id: string
  vlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/vlans/{vlanId}"
    path_params: [{name: networkId, var: network_id}, {name: vlanId, var: vlan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, vlan_id: $vlan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a VLAN
#
# PUT /networks/{networkId}/vlans/{vlanId}
# Returns: record
# operationId: updateNetworkVlan
export def "update-network-vlan" [
  network_id: string
  vlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --appliance-ip: string # The local IP of the appliance on the VLAN
  --dhcp-boot-filename: string # DHCP boot option for boot filename
  --dhcp-boot-next-server: string # DHCP boot option to direct boot clients to the server to load the boot file from
  --dhcp-boot-options-enabled: oneof<nothing, bool> # Use DHCP boot options specified in other properties
  --dhcp-handling: string@dhcp-handling-completer # The appliance's handling of DHCP requests on this VLAN. One of: 'Run a DHCP server', 'Relay DHCP to another server' or 'Do not respond to DHCP requests'
  --dhcp-lease-time: string@dhcp-lease-time-completer # The term of DHCP leases if the appliance is running a DHCP server on this VLAN. One of: '30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week'
  --dhcp-options: list # The list of DHCP options that will be included in DHCP responses. Each object in the list should have "code", "type", and "value" properties. — item shape: {code: string, type: "hex"|"integer"|"ip"|"text", value: string}
  --dhcp-relay-server-ips: list<string> # The IPs of the DHCP servers that DHCP requests should be relayed to
  --dns-nameservers: string # The DNS nameservers used for DHCP responses, either "upstream_dns", "google_dns", "opendns", or a newline seperated string of IP addresses or domain names
  --fixed-ip-assignments: record # The DHCP fixed IP assignments on the VLAN. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --group-policy-id: string # The id of the desired group policy to apply to the VLAN
  --name: string # The name of the VLAN
  --reserved-ip-ranges: list # The DHCP reserved IP ranges on the VLAN — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the VLAN
  --vpn-nat-subnet: string # The translated VPN subnet if VPN and VPN subnet translation are enabled on the VLAN
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/vlans/{vlanId}"
    path_params: [{name: networkId, var: network_id}, {name: vlanId, var: vlan_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: applianceIp, var: appliance_ip}, {name: dhcpBootFilename, var: dhcp_boot_filename}, {name: dhcpBootNextServer, var: dhcp_boot_next_server}, {name: dhcpBootOptionsEnabled, var: dhcp_boot_options_enabled}, {name: dhcpHandling, var: dhcp_handling}, {name: dhcpLeaseTime, var: dhcp_lease_time}, {name: dhcpOptions, var: dhcp_options}, {name: dhcpRelayServerIps, var: dhcp_relay_server_ips}, {name: dnsNameservers, var: dns_nameservers}, {name: fixedIpAssignments, var: fixed_ip_assignments}, {name: groupPolicyId, var: group_policy_id}, {name: name, var: name}, {name: reservedIpRanges, var: reserved_ip_ranges}, {name: subnet, var: subnet}, {name: vpnNatSubnet, var: vpn_nat_subnet}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, vlan_id: $vlan_id, appliance_ip: $appliance_ip, dhcp_boot_filename: $dhcp_boot_filename, dhcp_boot_next_server: $dhcp_boot_next_server, dhcp_boot_options_enabled: $dhcp_boot_options_enabled, dhcp_handling: $dhcp_handling, dhcp_lease_time: $dhcp_lease_time, dhcp_options: $dhcp_options, dhcp_relay_server_ips: $dhcp_relay_server_ips, dns_nameservers: $dns_nameservers, fixed_ip_assignments: $fixed_ip_assignments, group_policy_id: $group_policy_id, name: $name, reserved_ip_ranges: $reserved_ip_ranges, subnet: $subnet, vpn_nat_subnet: $vpn_nat_subnet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the enabled status of VLANs for the network
#
# GET /networks/{networkId}/vlansEnabledState
# Returns: record
# operationId: getNetworkVlansEnabledState
export def "get-network-vlans-enabled-state" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/vlansEnabledState"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/Disable VLANs for the given network
#
# PUT /networks/{networkId}/vlansEnabledState
# Returns: record
# operationId: updateNetworkVlansEnabledState
export def "update-network-vlans-enabled-state" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Boolean indicating whether to enable (true) or disable (false) VLANs for the network
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/vlansEnabledState"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return MX warm spare settings
#
# GET /networks/{networkId}/warmSpareSettings
# Returns: record
# operationId: getNetworkWarmSpareSettings
export def "get-network-warm-spare-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/warmSpareSettings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update MX warm spare settings
#
# PUT /networks/{networkId}/warmSpareSettings
# Returns: record
# operationId: updateNetworkWarmSpareSettings
export def "update-network-warm-spare-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Enable warm spare
  --spare-serial: string # Serial number of the warm spare appliance
  --uplink-mode: string # Uplink mode, either virtual or public
  --virtual-ip1: string # The WAN 1 shared IP
  --virtual-ip2: string # The WAN 2 shared IP
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/warmSpareSettings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled, required: true}, {name: spareSerial, var: spare_serial}, {name: uplinkMode, var: uplink_mode}, {name: virtualIp1, var: virtual_ip1}, {name: virtualIp2, var: virtual_ip2}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, enabled: $enabled, spare_serial: $spare_serial, uplink_mode: $uplink_mode, virtual_ip1: $virtual_ip1, virtual_ip2: $virtual_ip2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the non-basic RF profiles for this network
#
# GET /networks/{networkId}/wireless/rfProfiles
# Returns: list<record>
# operationId: getNetworkWirelessRfProfiles
export def "get-network-wireless-rf-profiles" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-template-profiles: oneof<nothing, bool> # If the network is bound to a template, this parameter controls whether or not the non-basic RF profiles defined on the template should be included in the response alongside the non-basic profiles defined on the bound network. Defaults to false.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{networkId}/wireless/rfProfiles"
    path_params: [{name: networkId, var: network_id}]
    query: [{name: includeTemplateProfiles, var: include_template_profiles}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, include_template_profiles: $include_template_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates new RF profile for this network
#
# POST /networks/{networkId}/wireless/rfProfiles
# Returns: record
# operationId: createNetworkWirelessRfProfile
export def "create-network-wireless-rf-profile" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-band-settings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  band_selection_type: string@band-selection-type-completer # Band selection can be set to either 'ssid' or 'ap'. This param is required on creation.
  --client-balancing-enabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false. Defaults to true.
  --five-ghz-settings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
  --min-bitrate-type: string@min-bitrate-type-completer # Minimum bitrate can be set to either 'band' or 'ssid'. Defaults to band.
  name: string # The name of the new profile. Must be unique. This param is required on creation.
  --two-four-ghz-settings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{networkId}/wireless/rfProfiles"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apBandSettings, var: ap_band_settings}, {name: bandSelectionType, var: band_selection_type}, {name: clientBalancingEnabled, var: client_balancing_enabled}, {name: fiveGhzSettings, var: five_ghz_settings}, {name: minBitrateType, var: min_bitrate_type}, {name: name, var: name}, {name: twoFourGhzSettings, var: two_four_ghz_settings}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ap_band_settings: $ap_band_settings, band_selection_type: $band_selection_type, client_balancing_enabled: $client_balancing_enabled, five_ghz_settings: $five_ghz_settings, min_bitrate_type: $min_bitrate_type, name: $name, two_four_ghz_settings: $two_four_ghz_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a RF Profile
#
# DELETE /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: deleteNetworkWirelessRfProfile
export def "delete-network-wireless-rf-profile" [
  network_id: string
  rf_profile_id: string
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
    path: "/networks/{networkId}/wireless/rfProfiles/{rfProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: rfProfileId, var: rf_profile_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rf_profile_id: $rf_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a RF profile
#
# GET /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# Returns: record
# operationId: getNetworkWirelessRfProfile
export def "get-network-wireless-rf-profile" [
  network_id: string
  rf_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/wireless/rfProfiles/{rfProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: rfProfileId, var: rf_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rf_profile_id: $rf_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates specified RF profile for this network
#
# PUT /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# Returns: record
# operationId: updateNetworkWirelessRfProfile
export def "update-network-wireless-rf-profile" [
  network_id: string
  rf_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-band-settings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  --band-selection-type: string@band-selection-type-completer # Band selection can be set to either 'ssid' or 'ap'.
  --client-balancing-enabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false.
  --five-ghz-settings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
  --min-bitrate-type: string@min-bitrate-type-completer # Minimum bitrate can be set to either 'band' or 'ssid'.
  --name: string # The name of the new profile. Must be unique.
  --two-four-ghz-settings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/wireless/rfProfiles/{rfProfileId}"
    path_params: [{name: networkId, var: network_id}, {name: rfProfileId, var: rf_profile_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apBandSettings, var: ap_band_settings}, {name: bandSelectionType, var: band_selection_type}, {name: clientBalancingEnabled, var: client_balancing_enabled}, {name: fiveGhzSettings, var: five_ghz_settings}, {name: minBitrateType, var: min_bitrate_type}, {name: name, var: name}, {name: twoFourGhzSettings, var: two_four_ghz_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, rf_profile_id: $rf_profile_id, ap_band_settings: $ap_band_settings, band_selection_type: $band_selection_type, client_balancing_enabled: $client_balancing_enabled, five_ghz_settings: $five_ghz_settings, min_bitrate_type: $min_bitrate_type, name: $name, two_four_ghz_settings: $two_four_ghz_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the wireless settings for a network
#
# GET /networks/{networkId}/wireless/settings
# Returns: record
# operationId: getNetworkWirelessSettings
export def "get-network-wireless-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/networks/{networkId}/wireless/settings"
    path_params: [{name: networkId, var: network_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the wireless settings for a network
#
# PUT /networks/{networkId}/wireless/settings
# Returns: record
# operationId: updateNetworkWirelessSettings
export def "update-network-wireless-settings" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ipv6-bridge-enabled: oneof<nothing, bool> # Toggle for enabling or disabling IPv6 bridging in a network (Note: if enabled, SSIDs must also be configured to use bridge mode)
  --led-lights-on: oneof<nothing, bool> # Toggle for enabling or disabling LED lights on all APs in the network (making them run dark)
  --location-analytics-enabled: oneof<nothing, bool> # Toggle for enabling or disabling location analytics for your network
  --meshing-enabled: oneof<nothing, bool> # Toggle for enabling or disabling meshing in a network
  --upgrade-strategy: string@upgrade-strategy-completer # The upgrade strategy to apply to the network. Must be one of 'minimizeUpgradeTime' or 'minimizeClientDowntime'. Requires firmware version MR 26.8 or higher'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{networkId}/wireless/settings"
    path_params: [{name: networkId, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ipv6BridgeEnabled, var: ipv6_bridge_enabled}, {name: ledLightsOn, var: led_lights_on}, {name: locationAnalyticsEnabled, var: location_analytics_enabled}, {name: meshingEnabled, var: meshing_enabled}, {name: upgradeStrategy, var: upgrade_strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ipv6_bridge_enabled: $ipv6_bridge_enabled, led_lights_on: $led_lights_on, location_analytics_enabled: $location_analytics_enabled, meshing_enabled: $meshing_enabled, upgrade_strategy: $upgrade_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lock a set of devices
#
# PUT /networks/{network_id}/sm/devices/lock
# Returns: record
# operationId: lockNetworkSmDevices
export def "lock-network-sm-devices" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be locked.
  --pin: int # The pin number for locking macOS devices (a six digit number). Required only for macOS devices.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be wiped.
  --serials: string # The serials of the devices to be locked.
  --wifi-macs: string # The wifiMacs of the devices to be locked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{network_id}/sm/devices/lock"
    path_params: [{name: network_id, var: network_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}, {name: pin, var: pin}, {name: scope, var: scope}, {name: serials, var: serials}, {name: wifiMacs, var: wifi_macs}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, ids: $ids, pin: $pin, scope: $scope, serials: $serials, wifi_macs: $wifi_macs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns historical connectivity data (whether a device is regularly checking in to Dashboard).
#
# GET /networks/{network_id}/sm/{id}/connectivity
# Returns: list<record>
# operationId: getNetworkSmConnectivity
export def "get-network-sm-connectivity" [
  network_id: string
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
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{network_id}/sm/{id}/connectivity"
    path_params: [{name: network_id, var: network_id}, {name: id, var: id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, id: $id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return historical records of various Systems Manager network connection details for desktop devices.
#
# GET /networks/{network_id}/sm/{id}/desktopLogs
# Returns: list<record>
# operationId: getNetworkSmDesktopLogs
export def "get-network-sm-desktop-logs" [
  network_id: string
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
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{network_id}/sm/{id}/desktopLogs"
    path_params: [{name: network_id, var: network_id}, {name: id, var: id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, id: $id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return historical records of commands sent to Systems Manager devices
#
# GET /networks/{network_id}/sm/{id}/deviceCommandLogs
# Returns: list<record>
# operationId: getNetworkSmDeviceCommandLogs
export def "get-network-sm-device-command-logs" [
  network_id: string
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
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{network_id}/sm/{id}/deviceCommandLogs"
    path_params: [{name: network_id, var: network_id}, {name: id, var: id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, id: $id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return historical records of various Systems Manager client metrics for desktop devices.
#
# GET /networks/{network_id}/sm/{id}/performanceHistory
# Returns: list<record>
# operationId: getNetworkSmPerformanceHistory
export def "get-network-sm-performance-history" [
  network_id: string
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
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{network_id}/sm/{id}/performanceHistory"
    path_params: [{name: network_id, var: network_id}, {name: id, var: id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    network_id: $network_id, id: $id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the organizations that the user has privileges on
#
# GET /organizations
# Returns: list<record>
# operationId: getOrganizations
export def "get-organizations" [
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
    path: "/organizations"
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return an organization
#
# GET /organizations/{organizationId}
# Returns: record
# operationId: getOrganization
export def "get-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the list of action batches in the organization
#
# GET /organizations/{organizationId}/actionBatches
# Returns: list<record>
# operationId: getOrganizationActionBatches
export def "get-organization-action-batches" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Filter batches by status. Valid types are pending, completed, and failed.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/actionBatches"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an action batch
#
# POST /organizations/{organizationId}/actionBatches
# Returns: record
# operationId: createOrganizationActionBatch
export def "create-organization-action-batch" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  actions: list # A set of changes to make as part of this action (more details) — item shape: {body?: record, operation: string, resource: string}
  --confirmed: oneof<nothing, bool> # Set to true for immediate execution. Set to false if the action should be previewed before executing. This property cannot be unset once it is true. Defaults to false.
  --synchronous: oneof<nothing, bool> # Set to true to force the batch to run synchronous. There can be at most 20 actions in synchronous batch. Defaults to false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/actionBatches"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actions, var: actions}, {name: confirmed, var: confirmed}, {name: synchronous, var: synchronous}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, actions: $actions, confirmed: $confirmed, synchronous: $synchronous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an action batch
#
# DELETE /organizations/{organizationId}/actionBatches/{actionBatchId}
# operationId: deleteOrganizationActionBatch
export def "delete-organization-action-batch" [
  organization_id: string
  action_batch_id: string
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
    path: "/organizations/{organizationId}/actionBatches/{actionBatchId}"
    path_params: [{name: organizationId, var: organization_id}, {name: actionBatchId, var: action_batch_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, action_batch_id: $action_batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an action batch
#
# PUT /organizations/{organizationId}/actionBatches/{actionBatchId}
# Returns: record
# operationId: updateOrganizationActionBatch
export def "update-organization-action-batch" [
  organization_id: string
  action_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmed: oneof<nothing, bool> # A boolean representing whether or not the batch has been confirmed. This property cannot be unset once it is true.
  --synchronous: oneof<nothing, bool> # Set to true to force the batch to run synchronous. There can be at most 20 actions in synchronous batch.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/actionBatches/{actionBatchId}"
    path_params: [{name: organizationId, var: organization_id}, {name: actionBatchId, var: action_batch_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: confirmed, var: confirmed}, {name: synchronous, var: synchronous}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, action_batch_id: $action_batch_id, confirmed: $confirmed, synchronous: $synchronous
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the dashboard administrators in this organization
#
# GET /organizations/{organizationId}/admins
# Returns: list<record>
# operationId: getOrganizationAdmins
export def "get-organization-admins" [
  organization_id: string
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
    path: "/organizations/{organizationId}/admins"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new dashboard administrator
#
# POST /organizations/{organizationId}/admins
# Returns: record
# operationId: createOrganizationAdmin
export def "create-organization-admin" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-method: string@authentication-method-completer # The method of authentication the user will use to sign in to the Meraki dashboard. Can be one of 'Email' or 'Cisco SecureX Sign-On'. The default is Email authentication
  email: string # The email of the dashboard administrator. This attribute can not be updated.
  name: string # The name of the dashboard administrator
  --networks: list # The list of networks that the dashboard administrator has privileges on — item shape: {access: string, id: string}
  org_access: string@org-access-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/admins"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticationMethod, var: authentication_method}, {name: email, var: email}, {name: name, var: name}, {name: networks, var: networks}, {name: orgAccess, var: org_access}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, authentication_method: $authentication_method, email: $email, name: $name, networks: $networks, org_access: $org_access, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke all access for a dashboard administrator within this organization
#
# DELETE /organizations/{organizationId}/admins/{adminId}
# operationId: deleteOrganizationAdmin
export def "delete-organization-admin" [
  organization_id: string
  admin_id: string
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
    path: "/organizations/{organizationId}/admins/{adminId}"
    path_params: [{name: organizationId, var: organization_id}, {name: adminId, var: admin_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, admin_id: $admin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an administrator
#
# PUT /organizations/{organizationId}/admins/{adminId}
# Returns: record
# operationId: updateOrganizationAdmin
export def "update-organization-admin" [
  organization_id: string
  admin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the dashboard administrator
  --networks: list # The list of networks that the dashboard administrator has privileges on — item shape: {access: string, id: string}
  --org-access: string@org-access-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/admins/{adminId}"
    path_params: [{name: organizationId, var: organization_id}, {name: adminId, var: admin_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: networks, var: networks}, {name: orgAccess, var: org_access}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, admin_id: $admin_id, name: $name, networks: $networks, org_access: $org_access, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the API requests made by an organization
#
# GET /organizations/{organizationId}/apiRequests
# Returns: list<record>
# operationId: getOrganizationApiRequests
export def "get-organization-api-requests" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 50.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --admin-id: string # Filter the results by the ID of the admin who made the API requests
  --path: string # Filter the results by the path of the API requests
  --method: string # Filter the results by the method of the API requests (must be 'GET', 'PUT', 'POST' or 'DELETE')
  --response-code: int # Filter the results by the response code of the API requests
  --source-ip: string # Filter the results by the IP address of the originating API request
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/apiRequests"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}, {name: adminId, var: admin_id}, {name: path, var: path}, {name: method, var: method}, {name: responseCode, var: response_code}, {name: sourceIp, var: source_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, t0: $t0, t1: $t1, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before, admin_id: $admin_id, path: $path, method: $method, response_code: $response_code, source_ip: $source_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return an aggregated overview of API requests data
#
# GET /organizations/{organizationId}/apiRequests/overview
# Returns: record
# operationId: getOrganizationApiRequestsOverview
export def "get-organization-api-requests-overview" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 31 days. (format: float)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/apiRequests/overview"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, t0: $t0, t1: $t1, timespan: $timespan
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Claim a list of devices, licenses, and/or orders into an organization
#
# POST /organizations/{organizationId}/claim
# Returns: record
# operationId: claimIntoOrganization
export def "claim-into-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --licenses: list # The licenses that should be claimed — item shape: {key: string, mode?: "addDevices"|"renew"}
  --orders: list<string> # The numbers of the orders that should be claimed
  --serials: list<string> # The serials of the devices that should be claimed
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/claim"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenses, var: licenses}, {name: orders, var: orders}, {name: serials, var: serials}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, licenses: $licenses, orders: $orders, serials: $serials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new organization by cloning the addressed organization
#
# POST /organizations/{organizationId}/clone
# Returns: record
# operationId: cloneOrganization
export def "clone-organization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new organization
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/clone"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the configuration templates for this organization
#
# GET /organizations/{organizationId}/configTemplates
# Returns: list<record>
# operationId: getOrganizationConfigTemplates
export def "get-organization-config-templates" [
  organization_id: string
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
    path: "/organizations/{organizationId}/configTemplates"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a configuration template
#
# DELETE /organizations/{organizationId}/configTemplates/{configTemplateId}
# operationId: deleteOrganizationConfigTemplate
export def "delete-organization-config-template" [
  organization_id: string
  config_template_id: string
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
    path: "/organizations/{organizationId}/configTemplates/{configTemplateId}"
    path_params: [{name: organizationId, var: organization_id}, {name: configTemplateId, var: config_template_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, config_template_id: $config_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the switch profiles for your switch template configuration
#
# GET /organizations/{organizationId}/configTemplates/{configTemplateId}/switchProfiles
# Returns: list<record>
# operationId: getOrganizationConfigTemplateSwitchProfiles
export def "get-organization-config-template-switch-profiles" [
  organization_id: string
  config_template_id: string
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
    path: "/organizations/{organizationId}/configTemplates/{configTemplateId}/switchProfiles"
    path_params: [{name: organizationId, var: organization_id}, {name: configTemplateId, var: config_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, config_template_id: $config_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View the Change Log for your organization
#
# GET /organizations/{organizationId}/configurationChanges
# Returns: list<record>
# operationId: getOrganizationConfigurationChanges
export def "get-organization-configuration-changes" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 365 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 5000. Default is 5000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --network-id: string # Filters on the given network
  --admin-id: string # Filters on the given Admin
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/configurationChanges"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}, {name: networkId, var: network_id}, {name: adminId, var: admin_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, t0: $t0, t1: $t1, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before, network_id: $network_id, admin_id: $admin_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the status of every Meraki device in the organization
#
# GET /organizations/{organizationId}/deviceStatuses
# Returns: list<record>
# operationId: getOrganizationDeviceStatuses
export def "get-organization-device-statuses" [
  organization_id: string
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
    path: "/organizations/{organizationId}/deviceStatuses"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the devices in an organization
#
# GET /organizations/{organizationId}/devices
# Returns: list<record>
# operationId: getOrganizationDevices
export def "get-organization-devices" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --configuration-updated-after: string # Filter results by whether or not the device's configuration has been updated after the given timestamp
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/devices"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}, {name: configurationUpdatedAfter, var: configuration_updated_after}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before, configuration_updated_after: $configuration_updated_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the monitored media servers for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers
# Returns: list<record>
# operationId: getOrganizationInsightMonitoredMediaServers
export def "get-organization-insight-monitored-media-servers" [
  organization_id: string
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
    path: "/organizations/{organizationId}/insight/monitoredMediaServers"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a media server to be monitored for this organization
#
# POST /organizations/{organizationId}/insight/monitoredMediaServers
# Returns: record
# operationId: createOrganizationInsightMonitoredMediaServer
export def "create-organization-insight-monitored-media-server" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The IP address (IPv4 only) or hostname of the media server to monitor
  name: string # The name of the VoIP provider
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/insight/monitoredMediaServers"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, address: $address, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a monitored media server from this organization
#
# DELETE /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: deleteOrganizationInsightMonitoredMediaServer
export def "delete-organization-insight-monitored-media-server" [
  organization_id: string
  monitored_media_server_id: string
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
    path: "/organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}"
    path_params: [{name: organizationId, var: organization_id}, {name: monitoredMediaServerId, var: monitored_media_server_id}]
    accept: ["application/json"]
    ok: [204]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, monitored_media_server_id: $monitored_media_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a monitored media server for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# Returns: record
# operationId: getOrganizationInsightMonitoredMediaServer
export def "get-organization-insight-monitored-media-server" [
  organization_id: string
  monitored_media_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}"
    path_params: [{name: organizationId, var: organization_id}, {name: monitoredMediaServerId, var: monitored_media_server_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, monitored_media_server_id: $monitored_media_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a monitored media server for this organization
#
# PUT /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# Returns: record
# operationId: updateOrganizationInsightMonitoredMediaServer
export def "update-organization-insight-monitored-media-server" [
  organization_id: string
  monitored_media_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The IP address (IPv4 only) or hostname of the media server to monitor
  --name: string # The name of the VoIP provider
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}"
    path_params: [{name: organizationId, var: organization_id}, {name: monitoredMediaServerId, var: monitored_media_server_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, monitored_media_server_id: $monitored_media_server_id, address: $address, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the inventory for an organization
#
# GET /organizations/{organizationId}/inventory
# Returns: list<record>
# operationId: getOrganizationInventory
export def "get-organization-inventory" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-license-info: oneof<nothing, bool> # When this parameter is true, each entity in the response will include the license expiration date of the device (if any). Only applies to organizations that are on the per-device licensing model. Defaults to false.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/inventory"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: includeLicenseInfo, var: include_license_info}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, include_license_info: $include_license_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return an overview of the license state for an organization
#
# GET /organizations/{organizationId}/licenseState
# Returns: record
# operationId: getOrganizationLicenseState
export def "get-organization-license-state" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/licenseState"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the licenses for an organization
#
# GET /organizations/{organizationId}/licenses
# Returns: list<record>
# operationId: getOrganizationLicenses
export def "get-organization-licenses" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --device-serial: string # Filter the licenses to those assigned to a particular device
  --network-id: string # Filter the licenses to those assigned in a particular network
  --state: string@state-completer # Filter the licenses to those in a particular state. Can be one of 'active', 'expired', 'expiring', 'recentlyQueued', 'unused' or 'unusedActive'
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/licenses"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}, {name: deviceSerial, var: device_serial}, {name: networkId, var: network_id}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before, device_serial: $device_serial, network_id: $network_id, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign SM seats to a network
#
# POST /organizations/{organizationId}/licenses/assignSeats
# Returns: record
# operationId: assignOrganizationLicensesSeats
export def "assign-organization-licenses-seats" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  license_id: string # The ID of the SM license to assign seats from
  network_id: string # The ID of the SM network to assign the seats to
  seat_count: int # The number of seats to assign to the SM network. Must be less than or equal to the total number of seats of the license
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/licenses/assignSeats"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseId, var: license_id}, {name: networkId, var: network_id}, {name: seatCount, var: seat_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, license_id: $license_id, network_id: $network_id, seat_count: $seat_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move SM seats to another organization
#
# POST /organizations/{organizationId}/licenses/moveSeats
# Returns: record
# operationId: moveOrganizationLicensesSeats
export def "move-organization-licenses-seats" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  dest_organization_id: string # The ID of the organization to move the SM seats to
  license_id: string # The ID of the SM license to move the seats from
  seat_count: int # The number of seats to move to the new organization. Must be less than or equal to the total number of seats of the license
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/licenses/moveSeats"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destOrganizationId, var: dest_organization_id}, {name: licenseId, var: license_id}, {name: seatCount, var: seat_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, dest_organization_id: $dest_organization_id, license_id: $license_id, seat_count: $seat_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renew SM seats of a license
#
# POST /organizations/{organizationId}/licenses/renewSeats
# Returns: record
# operationId: renewOrganizationLicensesSeats
export def "renew-organization-licenses-seats" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  license_id_to_renew: string # The ID of the SM license to renew. This license must already be assigned to an SM network
  unused_license_id: string # The SM license to use to renew the seats on 'licenseIdToRenew'. This license must have at least as many seats available as there are seats on 'licenseIdToRenew'
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/licenses/renewSeats"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: licenseIdToRenew, var: license_id_to_renew}, {name: unusedLicenseId, var: unused_license_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, license_id_to_renew: $license_id_to_renew, unused_license_id: $unused_license_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Display a license
#
# GET /organizations/{organizationId}/licenses/{licenseId}
# Returns: record
# operationId: getOrganizationLicense
export def "get-organization-license" [
  organization_id: string
  license_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/licenses/{licenseId}"
    path_params: [{name: organizationId, var: organization_id}, {name: licenseId, var: license_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, license_id: $license_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the networks in an organization
#
# GET /organizations/{organizationId}/networks
# Returns: list<record>
# operationId: getOrganizationNetworks
export def "get-organization-networks" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-template-id: string # An optional parameter that is the ID of a config template. Will return all networks bound to that template.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/networks"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: configTemplateId, var: config_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, config_template_id: $config_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a network
#
# POST /organizations/{organizationId}/networks
# Returns: record
# operationId: createOrganizationNetwork
export def "create-organization-network" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-from-network-id: string # The ID of the network to copy configuration from. Other provided parameters will override the copied configuration, except type which must match this network's type exactly.
  --disable-my-meraki-com: oneof<nothing, bool> # Disables the local device status pages (my.meraki.com, ap.meraki.com, switch.meraki.com, wired.meraki.com). Optional (defaults to false)
  --disable-remote-status-page: oneof<nothing, bool> # Disables access to the device status page (http://[device's LAN IP]). Optional. Can only be set if disableMyMerakiCom is set to false
  name: string # The name of the new network
  --tags: string # A space-separated list of tags to be applied to the network
  --time-zone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in this article.
  type: string # The type of the new network. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, environmental, or a space-separated list of those for a combined network.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/networks"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: copyFromNetworkId, var: copy_from_network_id}, {name: disableMyMerakiCom, var: disable_my_meraki_com}, {name: disableRemoteStatusPage, var: disable_remote_status_page}, {name: name, var: name}, {name: tags, var: tags}, {name: timeZone, var: time_zone}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, copy_from_network_id: $copy_from_network_id, disable_my_meraki_com: $disable_my_meraki_com, disable_remote_status_page: $disable_remote_status_page, name: $name, tags: $tags, time_zone: $time_zone, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Combine multiple networks into a single network
#
# POST /organizations/{organizationId}/networks/combine
# Returns: record
# operationId: combineOrganizationNetworks
export def "combine-organization-networks" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enrollment-string: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break. All networks that are part of this combined network will have their enrollment string appended by '-network_type'. If left empty, all exisitng enrollment strings will be deleted.
  name: string # The name of the combined network
  network_ids: list<string> # A list of the network IDs that will be combined. If an ID of a combined network is included in this list, the other networks in the list will be grouped into that network
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/networks/combine"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enrollmentString, var: enrollment_string}, {name: name, var: name}, {name: networkIds, var: network_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, enrollment_string: $enrollment_string, name: $name, network_ids: $network_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the OpenAPI 2.0 Specification of the organization's API documentation in JSON
#
# GET /organizations/{organizationId}/openapiSpec
# Returns: record
# operationId: getOrganizationOpenapiSpec
export def "get-organization-openapi-spec" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/openapiSpec"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the SAML roles for this organization
#
# GET /organizations/{organizationId}/samlRoles
# Returns: list<record>
# operationId: getOrganizationSamlRoles
export def "get-organization-saml-roles" [
  organization_id: string
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
    path: "/organizations/{organizationId}/samlRoles"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a SAML role
#
# POST /organizations/{organizationId}/samlRoles
# Returns: record
# operationId: createOrganizationSamlRole
export def "create-organization-saml-role" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  org_access: string # The privilege of the SAML administrator on the organization
  role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/{organizationId}/samlRoles"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: networks, var: networks}, {name: orgAccess, var: org_access}, {name: role, var: role}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, networks: $networks, org_access: $org_access, role: $role, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a SAML role
#
# GET /organizations/{organizationId}/samlRoles/{samlRoleId}
# Returns: record
# operationId: getOrganizationSamlRole
export def "get-organization-saml-role" [
  organization_id: string
  saml_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/samlRoles/{samlRoleId}"
    path_params: [{name: organizationId, var: organization_id}, {name: samlRoleId, var: saml_role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, saml_role_id: $saml_role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SAML role
#
# PUT /organizations/{organizationId}/samlRoles/{samlRoleId}
# Returns: record
# operationId: updateOrganizationSamlRole
export def "update-organization-saml-role" [
  organization_id: string
  saml_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  --org-access: string # The privilege of the SAML administrator on the organization
  --role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/samlRoles/{samlRoleId}"
    path_params: [{name: organizationId, var: organization_id}, {name: samlRoleId, var: saml_role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: networks, var: networks}, {name: orgAccess, var: org_access}, {name: role, var: role}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, saml_role_id: $saml_role_id, networks: $networks, org_access: $org_access, role: $role, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all supported intrusion settings for an organization
#
# GET /organizations/{organizationId}/security/intrusionSettings
# Returns: record
# operationId: getOrganizationSecurityIntrusionSettings
export def "get-organization-security-intrusion-settings" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/security/intrusionSettings"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets supported intrusion settings for an organization
#
# PUT /organizations/{organizationId}/security/intrusionSettings
# Returns: record
# operationId: updateOrganizationSecurityIntrusionSettings
export def "update-organization-security-intrusion-settings" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  whitelisted_rules: list # Sets a list of specific SNORT signatures to allow — item shape: {message?: string, ruleId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/security/intrusionSettings"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: whitelistedRules, var: whitelisted_rules}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, whitelisted_rules: $whitelisted_rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the security events (intrusion detection only) for an organization
#
# GET /organizations/{organizationId}/securityEvents
# Returns: list<record>
# operationId: getOrganizationSecurityEvents
export def "get-organization-security-events" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. Data is gathered after the specified t0 value. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/securityEvents"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: perPage, var: per_page}, {name: startingAfter, var: starting_after}, {name: endingBefore, var: ending_before}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, t0: $t0, t1: $t1, timespan: $timespan, per_page: $per_page, starting_after: $starting_after, ending_before: $ending_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the SNMP settings for an organization
#
# GET /organizations/{organizationId}/snmp
# Returns: record
# operationId: getOrganizationSnmp
export def "get-organization-snmp" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}/snmp"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the third party VPN peers for an organization
#
# GET /organizations/{organizationId}/thirdPartyVPNPeers
# Returns: list<record>
# operationId: getOrganizationThirdPartyVPNPeers
export def "get-organization-third-party-vpn-peers" [
  organization_id: string
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
    path: "/organizations/{organizationId}/thirdPartyVPNPeers"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the third party VPN peers for an organization
#
# PUT /organizations/{organizationId}/thirdPartyVPNPeers
# Returns: list<record>
# operationId: updateOrganizationThirdPartyVPNPeers
export def "update-organization-third-party-vpn-peers" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  peers: list # The list of VPN peers — item shape: {ikeVersion?: "1"|"2", ipsecPolicies?: record, ipsecPoliciesPreset?: string, name: string, networkTags?: list<string>, privateSubnets: list<string>, publicIp: string, remoteId?: string, secret: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/thirdPartyVPNPeers"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: peers, var: peers}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, peers: $peers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the uplink loss and latency for every MX in the organization from at latest 2 minutes ago
#
# GET /organizations/{organizationId}/uplinksLossAndLatency
# Returns: list<record>
# operationId: getOrganizationUplinksLossAndLatency
export def "get-organization-uplinks-loss-and-latency" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 60 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 5 minutes after t0. The latest possible time that t1 can be is 2 minutes into the past.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 5 minutes. The default is 5 minutes. (format: float)
  --uplink: string@uplink-completer # Optional filter for a specific WAN uplink. Valid uplinks are wan1, wan2, cellular. Default will return all uplinks.
  --ip: string # Optional filter for a specific destination IP. Default will return all destination IPs.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/organizations/{organizationId}/uplinksLossAndLatency"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: t0, var: t0}, {name: t1, var: t1}, {name: timespan, var: timespan}, {name: uplink, var: uplink}, {name: ip, var: ip}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, t0: $t0, t1: $t1, timespan: $timespan, uplink: $uplink, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return the firewall rules for an organization's site-to-site VPN
#
# GET /organizations/{organizationId}/vpnFirewallRules
# Returns: list<record>
# operationId: getOrganizationVpnFirewallRules
export def "get-organization-vpn-firewall-rules" [
  organization_id: string
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
    path: "/organizations/{organizationId}/vpnFirewallRules"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the firewall rules of an organization's site-to-site VPN
#
# PUT /organizations/{organizationId}/vpnFirewallRules
# Returns: list<record>
# operationId: updateOrganizationVpnFirewallRules
export def "update-organization-vpn-firewall-rules" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/organizations/{organizationId}/vpnFirewallRules"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}, {name: syslogDefaultRule, var: syslog_default_rule}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-cisco-meraki-api-key
  } {
    organization_id: $organization_id, rules: $rules, syslog_default_rule: $syslog_default_rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
