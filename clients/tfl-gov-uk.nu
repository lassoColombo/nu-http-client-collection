# Auto-generated client for Transport for London Unified API v1
# Source: https://api.apis.guru/v2/specs/tfl.gov.uk/v1/openapi.json
# Auth: --token flag or $env.TRANSPORT_FOR_LONDON_UNIFIED_API_TOKEN

const CLIENT = {
  base_url: "https://api.digital.tfl.gov.uk"
  token_env_var: "TRANSPORT_FOR_LONDON_UNIFIED_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-app_key, in: query, header_name: app_key, prefix: ""}
    {name: query-app_id, in: query, header_name: app_id, prefix: ""}
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

def base-url-completer [] { ["https://api.digital.tfl.gov.uk"] }
def auth-scheme-completer [] { ["query-app_key" "query-app_id"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def time-is-completer [] { ["Arriving" "Departing"] }
def journey-preference-completer [] { ["LeastInterchange" "LeastTime" "LeastWalking"] }
def walking-speed-completer [] { ["Average" "Fast" "Slow"] }
def cycle-preference-completer [] { ["AllTheWay" "CycleHire" "LeaveAtStation" "None" "TakeOnTransport"] }
def direction-completer [] { ["all" "inbound" "outbound"] }
def accept-completer-1 [] { ["application/geo+json" "application/json" "application/xml" "text/json" "text/xml"] }
def direction-completer-1 [] { ["Average" "From" "To"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accident-stats-get: "table<borough: string, casualties: list<record>, date: string, id: int, lat: float, location: string, lon: float, severity: string, vehicles: list<record>>"
    air-quality-get: "record"
    bike-point-get-all: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    bike-point-search: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    bike-point-get: "record<additionalProperties: table<category: string, key: string, modified: string, sourceSystemKey: string, value: string>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    cabwise-get: "record"
    journey-journey-results: "record<cycleHireDockingStationData: record<destinationId: string, destinationNumberOfBikes: int, destinationNumberOfEmptySlots: int, originId: string, originNumberOfBikes: int, originNumberOfEmptySlots: int>, journeyVector: record<from: string, to: string, uri: string, via: string>, journeys: table<arrivalDateTime: string, duration: int, fare: record, legs: list, startDateTime: string>, lines: table<created: string, crowding: record, disruptions: list, id: string, lineStatuses: list, modeName: string, modified: string, name: string, routeSections: list, serviceTypes: list>, recommendedMaxAgeMinutes: int, searchCriteria: record<dateTime: string, dateTimeType: string, timeAdjustments: record<earlier: record, earliest: record, later: record, latest: record>>, stopMessages: list<string>>"
    journey-meta: "table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>"
    line-meta-disruption-categories: "list<string>"
    line-meta-modes: "table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>"
    line-meta-service-types: "list<string>"
    line-meta-severity: "table<description: string, modeName: string, severityLevel: int>"
    line-get-by-mode: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-disruption-by-mode: "table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string>"
    line-route-by-mode: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-status-by-mode: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-route: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-search: "record<input: string, searchMatches: table<id: string, lat: float, lineId: string, lineName: string, lineRouteSection: list, lon: float, matchedRouteSections: list, matchedStops: list, mode: string, name: string, url: string>>"
    line-status-by-severity: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-get: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-arrivals: "table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>"
    line-disruption: "table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string>"
    line-line-routes-by-ids: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-status-by-ids: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-status: "table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>"
    line-route-sequence: "record<direction: string, isOutboundOnly: bool, lineId: string, lineName: string, lineStrings: list<string>, mode: string, orderedLineRoutes: table<name: string, naptanIds: list, serviceType: string>, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, stopPointSequences: table<branchId: int, direction: string, lineId: string, lineName: string, nextBranchIds: list, prevBranchIds: list, serviceType: string, stopPoint: list>>"
    line-stop-points: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    line-timetable: "record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>>"
    line-timetable-to: "record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>>"
    mode-get-active-service-types: "table<mode: string, serviceType: string>"
    mode-arrivals: "table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>"
    occupancy-get-bike-points-occupancies: "table<bikesCount: int, eBikesCount: int, emptyDocks: int, id: string, name: string, standardBikesCount: int, totalDocks: int>"
    get-occupancy-car-park: "table<bays: list<record>, carParkDetailsUrl: string, id: string, name: string>"
    occupancy-get: "record<bays: table<bayCount: int, bayType: string, free: int, occupied: int>, carParkDetailsUrl: string, id: string, name: string>"
    occupancy-get-all-charge-connector-status: "table<id: int, sourceSystemPlaceId: string, status: string>"
    occupancy-get-charge-connector-status: "table<id: int, sourceSystemPlaceId: string, status: string>"
    place-get-by-geo: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    place-get-streets-by-post-code: "record"
    place-meta-categories: "table<availableKeys: list<string>, category: string>"
    place-meta-place-types: "table<availableKeys: list<string>, category: string>"
    place-search: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    place-get-by-type: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    place-get: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    place-get-at: "record"
    place-get-overlay: "record"
    road-get: "table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>"
    road-meta-categories: "list<string>"
    road-meta-severities: "table<description: string, modeName: string, severityLevel: int>"
    road-disruption-by-id: "record<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, geometry: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: table<endTime: string, startTime: string>, roadDisruptionImpactAreas: table<endDate: string, endTime: string, id: int, polygon: record, roadDisruptionId: string, startDate: string, startTime: string>, roadDisruptionLines: table<endDate: string, endTime: string, id: int, isDiversion: bool, multiLineString: record, roadDisruptionId: string, startDate: string, startTime: string>, roadProject: record<boroughsBenefited: list<string>, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: table<closure: string, directions: string, name: string, segments: list, sourceSystemId: int, sourceSystemKey: string>, subCategory: string, timeFrame: string, url: string>"
    road-disrupted-streets: "record"
    get-road-ids: "table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>"
    road-disruption: "table<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record>, geometry: record<geography: record>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: list<record>, roadDisruptionImpactAreas: list<record>, roadDisruptionLines: list<record>, roadProject: record<boroughsBenefited: list, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: list<record>, subCategory: string, timeFrame: string, url: string>"
    road-status: "table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>"
    search-get: "record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>"
    search-bus-schedules: "record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>"
    search-meta-categories: "list<string>"
    search-meta-search-providers: "list<string>"
    search-meta-sorts: "list<string>"
    stop-point-get-by-geo-point: "record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int>"
    stop-point-meta-categories: "table<availableKeys: list<string>, category: string>"
    stop-point-meta-modes: "table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>"
    stop-point-meta-stop-types: "list<string>"
    stop-point-get-by-mode: "record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int>"
    stop-point-disruption-by-mode: "table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string>"
    get-stop-point-search: "record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>"
    stop-point-search: "record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>"
    stop-point-get-service-types: "table<lineName: string, lineSpecificServiceTypes: list<record>>"
    stop-point-get-by-sms: "record"
    stop-point-get-by-type: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    stop-point-get-by-type-with-pagination: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    stop-point-get: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    stop-point-disruption: "table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string>"
    stop-point-arrival-departures: "table<cause: string, departureStatus: string, destinationName: string, destinationNaptanId: string, estimatedTimeOfArrival: string, estimatedTimeOfDeparture: string, minutesAndSecondsToArrival: string, minutesAndSecondsToDeparture: string, naptanId: string, platformName: string, scheduledTimeOfArrival: string, scheduledTimeOfDeparture: string, stationName: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>>"
    stop-point-arrivals: "table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>"
    stop-point-reachable-from: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    stop-point-crowding: "table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>"
    stop-point-direction: "string"
    stop-point-route: "table<destinationName: string, direction: string, isActive: bool, lineId: string, lineString: string, mode: string, naptanId: string, routeSectionName: string, serviceType: string, validFrom: string, validTo: string, vehicleDestinationText: string>"
    get-stop-point-id-place-types: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    stop-point-get-car-parks-by-id: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    stop-point-get-taxi-ranks-by-ids: "table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>"
    travel-time-get-compare-overlay: "record"
    travel-time-get-overlay: "record"
    vehicle-get: "table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accident-stats-get" "air-quality-get" "bike-point-get-all" "bike-point-search" "bike-point-get" "cabwise-get" "journey-journey-results" "journey-meta" "line-meta-disruption-categories" "line-meta-modes" "line-meta-service-types" "line-meta-severity" "line-get-by-mode" "line-disruption-by-mode" "line-route-by-mode" "line-status-by-mode" "line-route" "line-search" "line-status-by-severity" "line-get" "line-arrivals" "line-disruption" "line-line-routes-by-ids" "line-status-by-ids" "line-status" "line-route-sequence" "line-stop-points" "line-timetable" "line-timetable-to" "mode-get-active-service-types" "mode-arrivals" "occupancy-get-bike-points-occupancies" "get-occupancy-car-park" "occupancy-get" "occupancy-get-all-charge-connector-status" "occupancy-get-charge-connector-status" "place-get-by-geo" "place-get-streets-by-post-code" "place-meta-categories" "place-meta-place-types" "place-search" "place-get-by-type" "place-get" "place-get-at" "place-get-overlay" "road-get" "road-meta-categories" "road-meta-severities" "road-disruption-by-id" "road-disrupted-streets" "get-road-ids" "road-disruption" "road-status" "search-get" "search-bus-schedules" "search-meta-categories" "search-meta-search-providers" "search-meta-sorts" "stop-point-get-by-geo-point" "stop-point-meta-categories" "stop-point-meta-modes" "stop-point-meta-stop-types" "stop-point-get-by-mode" "stop-point-disruption-by-mode" "get-stop-point-search" "stop-point-search" "stop-point-get-service-types" "stop-point-get-by-sms" "stop-point-get-by-type" "stop-point-get-by-type-with-pagination" "stop-point-get" "stop-point-disruption" "stop-point-arrival-departures" "stop-point-arrivals" "stop-point-reachable-from" "stop-point-crowding" "stop-point-direction" "stop-point-route" "get-stop-point-id-place-types" "stop-point-get-car-parks-by-id" "stop-point-get-taxi-ranks-by-ids" "travel-time-get-compare-overlay" "travel-time-get-overlay" "vehicle-get" "commands"] | sort) } | get name | first)
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

# Gets all accident details for accidents occuring in the specified year
#
# GET /AccidentStats/{year}
# Returns: table<borough: string, casualties: list<record>, date: string, id: int, lat: float, location: string, lon: float, severity: string, vehicles: list<record>>
# operationId: AccidentStats_Get
export def "accident-stats-get" [
  year: int
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
    path: "/AccidentStats/{year}"
    path_params: [{name: year, var: year}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets air quality data feed
#
# GET /AirQuality
# Returns: record
# operationId: AirQuality_Get
export def "air-quality-get" [
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
    path: "/AirQuality"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all bike point locations. The Place object has an addtionalProperties array which contains the nbBikes, nbDocks and nbSpaces numbers which give the status of the BikePoint. A mismatch in these numbers i.e. nbDocks - (nbBikes + nbSpaces) != 0 indicates broken docks.
#
# GET /BikePoint
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: BikePoint_GetAll
export def "bike-point-get-all" [
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
    path: "/BikePoint"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for bike stations by their name, a bike point's name often contains information about the name of the street or nearby landmarks, for example. Note that the search result does not contain the PlaceProperties i.e. the status or occupancy of the BikePoint, to get that information you should retrieve the BikePoint by its id on /BikePoint/id.
#
# GET /BikePoint/Search
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: BikePoint_Search
export def "bike-point-search" [
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
  --query: string # The search term e.g. "St. James" (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/BikePoint/Search"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the bike point with the given id.
#
# GET /BikePoint/{id}
# Returns: record<additionalProperties: table<category: string, key: string, modified: string, sourceSystemKey: string, value: string>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: BikePoint_Get
export def "bike-point-get" [
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
    path: "/BikePoint/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets taxis and minicabs contact information
#
# GET /Cabwise/search
# Returns: record
# operationId: Cabwise_Get
export def "cabwise-get" [
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
  --lat: float # Latitude (required, format: double)
  --lon: float # Longitude (required, format: double)
  --optype: string # Operator Type e.g Minicab, Executive, Limousine
  --wc: string # Wheelchair accessible
  --radius: float # The radius of the bounding circle in metres (format: double)
  --name: string # Trading name of operating company
  --max-results: int # An optional parameter to limit the number of results return. Default and maximum is 20. (format: int32)
  --legacy-format: oneof<nothing, bool> # Legacy Format
  --force-xml: oneof<nothing, bool> # Force Xml
  --twenty-four-seven-only: oneof<nothing, bool> # Twenty Four Seven Only
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Cabwise/search"
    query: [{name: lat, var: lat, required: true}, {name: lon, var: lon, required: true}, {name: optype, var: optype}, {name: wc, var: wc}, {name: radius, var: radius}, {name: name, var: name}, {name: maxResults, var: max_results}, {name: legacyFormat, var: legacy_format}, {name: forceXml, var: force_xml}, {name: twentyFourSevenOnly, var: twenty_four_seven_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    lat: $lat, lon: $lon, optype: $optype, wc: $wc, radius: $radius, name: $name, max_results: $max_results, legacy_format: $legacy_format, force_xml: $force_xml, twenty_four_seven_only: $twenty_four_seven_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Perform a Journey Planner search from the parameters specified in simple types
#
# GET /Journey/JourneyResults/{from}/to/{to}
# Returns: record<cycleHireDockingStationData: record<destinationId: string, destinationNumberOfBikes: int, destinationNumberOfEmptySlots: int, originId: string, originNumberOfBikes: int, originNumberOfEmptySlots: int>, journeyVector: record<from: string, to: string, uri: string, via: string>, journeys: table<arrivalDateTime: string, duration: int, fare: record, legs: list, startDateTime: string>, lines: table<created: string, crowding: record, disruptions: list, id: string, lineStatuses: list, modeName: string, modified: string, name: string, routeSections: list, serviceTypes: list>, recommendedMaxAgeMinutes: int, searchCriteria: record<dateTime: string, dateTimeType: string, timeAdjustments: record<earlier: record, earliest: record, later: record, latest: record>>, stopMessages: list<string>>
# operationId: Journey_JourneyResults
export def "journey-journey-results" [
  from: string
  to: string
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
  --via: string # Travel through point on the journey. Can be WGS84 coordinates expressed as "lat,long", a UK postcode, a Naptan (StopPoint) id, an ICS StopId, or a free-text string (will cause disambiguation unless it exactly matches a point of interest name).
  --national-search: oneof<nothing, bool> # Does the journey cover stops outside London? eg. "nationalSearch=true"
  --date: string # The date must be in yyyyMMdd format
  --time: string # The time must be in HHmm format
  --time-is: string@time-is-completer # Does the time given relate to arrival or leaving time? Possible options: "departing" | "arriving"
  --journey-preference: string@journey-preference-completer # The journey preference eg possible options: "leastinterchange" | "leasttime" | "leastwalking"
  --mode: list<string> # The mode must be a comma separated list of modes. eg possible options: "public-bus,overground,train,tube,coach,dlr,cablecar,tram,river,walking,cycle"
  --accessibility-preference: list<string> # The accessibility preference must be a comma separated list eg. "noSolidStairs,noEscalators,noElevators,stepFreeToVehicle,stepFreeToPlatform"
  --from-name: string # An optional name to associate with the origin of the journey in the results.
  --to-name: string # An optional name to associate with the destination of the journey in the results.
  --via-name: string # An optional name to associate with the via point of the journey in the results.
  --max-transfer-minutes: string # The max walking time in minutes for transfer eg. "120"
  --max-walking-minutes: string # The max walking time in minutes for journeys eg. "120"
  --walking-speed: string@walking-speed-completer # The walking speed. eg possible options: "slow" | "average" | "fast".
  --cycle-preference: string@cycle-preference-completer # The cycle preference. eg possible options: "allTheWay" | "leaveAtStation" | "takeOnTransport" | "cycleHire"
  --adjustment: string # Time adjustment command. eg possible options: "TripFirst" | "TripLast"
  --bike-proficiency: list<string> # A comma separated list of cycling proficiency levels. eg possible options: "easy,moderate,fast"
  --alternative-cycle: oneof<nothing, bool> # Option to determine whether to return alternative cycling journey
  --alternative-walking: oneof<nothing, bool> # Option to determine whether to return alternative walking journey
  --apply-html-markup: oneof<nothing, bool> # Flag to determine whether certain text (e.g. walking instructions) should be output with HTML tags or not.
  --use-multi-modal-call: oneof<nothing, bool> # A boolean to indicate whether or not to return 3 public transport journeys, a bus journey, a cycle hire journey, a personal cycle journey and a walking journey
  --walking-optimization: oneof<nothing, bool> # A boolean to indicate whether to optimize journeys using walking
  --taxi-only-trip: oneof<nothing, bool> # A boolean to indicate whether to return one or more taxi journeys. Note, setting this to true will override "useMultiModalCall".
  --route-between-entrances: oneof<nothing, bool> # A boolean to indicate whether public transport routes should include directions between platforms and station entrances.
  --use-real-time-live-arrivals: oneof<nothing, bool> # A boolean to indicate if we want to receive real time live arrivals data where available.
  --calc-one-direction: oneof<nothing, bool> # A boolean to make Journey Planner calculate journeys in one temporal direction only. In other words, only calculate journeys after the 'depart' time, or before the 'arrive' time. By default, the Journey Planner engine (EFA) calculates journeys in both temporal directions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Journey/JourneyResults/{from}/to/{to}"
    path_params: [{name: from, var: from}, {name: to, var: to}]
    query: [{name: via, var: via}, {name: nationalSearch, var: national_search}, {name: date, var: date}, {name: time, var: time}, {name: timeIs, var: time_is}, {name: journeyPreference, var: journey_preference}, {name: mode, var: mode, style: multi}, {name: accessibilityPreference, var: accessibility_preference, style: multi}, {name: fromName, var: from_name}, {name: toName, var: to_name}, {name: viaName, var: via_name}, {name: maxTransferMinutes, var: max_transfer_minutes}, {name: maxWalkingMinutes, var: max_walking_minutes}, {name: walkingSpeed, var: walking_speed}, {name: cyclePreference, var: cycle_preference}, {name: adjustment, var: adjustment}, {name: bikeProficiency, var: bike_proficiency, style: multi}, {name: alternativeCycle, var: alternative_cycle}, {name: alternativeWalking, var: alternative_walking}, {name: applyHtmlMarkup, var: apply_html_markup}, {name: useMultiModalCall, var: use_multi_modal_call}, {name: walkingOptimization, var: walking_optimization}, {name: taxiOnlyTrip, var: taxi_only_trip}, {name: routeBetweenEntrances, var: route_between_entrances}, {name: useRealTimeLiveArrivals, var: use_real_time_live_arrivals}, {name: calcOneDirection, var: calc_one_direction}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    from: $from, to: $to, via: $via, national_search: $national_search, date: $date, time: $time, time_is: $time_is, journey_preference: $journey_preference, mode: $mode, accessibility_preference: $accessibility_preference, from_name: $from_name, to_name: $to_name, via_name: $via_name, max_transfer_minutes: $max_transfer_minutes, max_walking_minutes: $max_walking_minutes, walking_speed: $walking_speed, cycle_preference: $cycle_preference, adjustment: $adjustment, bike_proficiency: $bike_proficiency, alternative_cycle: $alternative_cycle, alternative_walking: $alternative_walking, apply_html_markup: $apply_html_markup, use_multi_modal_call: $use_multi_modal_call, walking_optimization: $walking_optimization, taxi_only_trip: $taxi_only_trip, route_between_entrances: $route_between_entrances, use_real_time_live_arrivals: $use_real_time_live_arrivals, calc_one_direction: $calc_one_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of all of the available journey planner modes
#
# GET /Journey/Meta/Modes
# Returns: table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>
# operationId: Journey_Meta
export def "journey-meta" [
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
    path: "/Journey/Meta/Modes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid disruption categories
#
# GET /Line/Meta/DisruptionCategories
# Returns: list<string>
# operationId: Line_MetaDisruptionCategories
export def "line-meta-disruption-categories" [
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
    path: "/Line/Meta/DisruptionCategories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid modes
#
# GET /Line/Meta/Modes
# Returns: table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>
# operationId: Line_MetaModes
export def "line-meta-modes" [
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
    path: "/Line/Meta/Modes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid ServiceTypes to filter on
#
# GET /Line/Meta/ServiceTypes
# Returns: list<string>
# operationId: Line_MetaServiceTypes
export def "line-meta-service-types" [
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
    path: "/Line/Meta/ServiceTypes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid severity codes
#
# GET /Line/Meta/Severity
# Returns: table<description: string, modeName: string, severityLevel: int>
# operationId: Line_MetaSeverity
export def "line-meta-severity" [
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
    path: "/Line/Meta/Severity"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets lines that serve the given modes.
#
# GET /Line/Mode/{modes}
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_GetByMode
export def "line-get-by-mode" [
  modes: list<string>
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
    path: "/Line/Mode/{modes}"
    path_params: [{name: modes, var: modes, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get disruptions for all lines of the given modes.
#
# GET /Line/Mode/{modes}/Disruption
# Returns: table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string>
# operationId: Line_DisruptionByMode
export def "line-disruption-by-mode" [
  modes: list<string>
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
    path: "/Line/Mode/{modes}/Disruption"
    path_params: [{name: modes, var: modes, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all lines and their valid routes for given modes, including the name and id of the originating and terminating stops for each route
#
# GET /Line/Mode/{modes}/Route
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_RouteByMode
export def "line-route-by-mode" [
  modes: list<string>
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
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/Mode/{modes}/Route"
    path_params: [{name: modes, var: modes, encode: array}]
    query: [{name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes, service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the line status of for all lines for the given modes
#
# GET /Line/Mode/{modes}/Status
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_StatusByMode
export def "line-status-by-mode" [
  modes: list<string>
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
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
  --severity-level: string # If specified, ensures that only those line status(es) are returned within the lines that have disruptions with the matching severity level.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/Mode/{modes}/Status"
    path_params: [{name: modes, var: modes, encode: array}]
    query: [{name: detail, var: detail}, {name: severityLevel, var: severity_level}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes, detail: $detail, severity_level: $severity_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all valid routes for all lines, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/Route
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_Route
export def "line-route" [
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
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/Route"
    query: [{name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for lines or routes matching the query string
#
# GET /Line/Search/{query}
# Returns: record<input: string, searchMatches: table<id: string, lat: float, lineId: string, lineName: string, lineRouteSection: list, lon: float, matchedRouteSections: list, matchedStops: list, mode: string, name: string, url: string>>
# operationId: Line_Search
export def "line-search" [
  query: string
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
  --modes: list<string> # Optionally filter by the specified modes
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Line/Search/{query}"
    path_params: [{name: query, var: query}]
    query: [{name: modes, var: modes, style: multi}, {name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query, modes: $modes, service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the line status for all lines with a given severity A list of valid severity codes can be obtained from a call to Line/Meta/Severity
#
# GET /Line/Status/{severity}
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_StatusBySeverity
export def "line-status-by-severity" [
  severity: int
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
    path: "/Line/Status/{severity}"
    path_params: [{name: severity, var: severity}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    severity: $severity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets lines that match the specified line ids.
#
# GET /Line/{ids}
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_Get
export def "line-get" [
  ids: list<string>
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
    path: "/Line/{ids}"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the list of arrival predictions for given line ids based at the given stop
#
# GET /Line/{ids}/Arrivals/{stopPointId}
# Returns: table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>
# operationId: Line_Arrivals
export def "line-arrivals" [
  ids: list<string>
  stop_point_id: string
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
  --direction: string@direction-completer # Optional. The direction of travel. Can be inbound or outbound or all. If left blank, and destinationStopId is set, will default to all
  --destination-station-id: string # Optional. Id of destination stop
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{ids}/Arrivals/{stopPointId}"
    path_params: [{name: ids, var: ids, encode: array}, {name: stopPointId, var: stop_point_id}]
    query: [{name: direction, var: direction}, {name: destinationStationId, var: destination_station_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, stop_point_id: $stop_point_id, direction: $direction, destination_station_id: $destination_station_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get disruptions for the given line ids
#
# GET /Line/{ids}/Disruption
# Returns: table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string>
# operationId: Line_Disruption
export def "line-disruption" [
  ids: list<string>
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
    path: "/Line/{ids}/Disruption"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all valid routes for given line ids, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/{ids}/Route
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_LineRoutesByIds
export def "line-line-routes-by-ids" [
  ids: list<string>
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
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{ids}/Route"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the line status of for given line ids e.g Minor Delays
#
# GET /Line/{ids}/Status
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_StatusByIds
export def "line-status-by-ids" [
  ids: list<string>
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
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{ids}/Status"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: detail, var: detail}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, detail: $detail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the line status for given line ids during the provided dates e.g Minor Delays
#
# GET /Line/{ids}/Status/{StartDate}/to/{EndDate}
# Returns: table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>>
# operationId: Line_Status
export def "line-status" [
  ids: list<string>
  start_date: string
  end_date: string
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
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
  --qp-start-date: string # required (spec name: startDate)
  --qp-end-date: string # required (spec name: endDate)
  --date-range-start-date: string # format: date-time
  --date-range-end-date: string # format: date-time
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{ids}/Status/{StartDate}/to/{EndDate}"
    path_params: [{name: ids, var: ids, encode: array}, {name: StartDate, var: start_date}, {name: EndDate, var: end_date}]
    query: [{name: detail, var: detail}, {name: startDate, var: qp_start_date, required: true}, {name: endDate, var: qp_end_date, required: true}, {name: "dateRange.startDate", var: date_range_start_date}, {name: "dateRange.endDate", var: date_range_end_date}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, start_date: $start_date, end_date: $end_date, detail: $detail, qp_start_date: $qp_start_date, qp_end_date: $qp_end_date, date_range_start_date: $date_range_start_date, date_range_end_date: $date_range_end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all valid routes for given line id, including the sequence of stops on each route.
#
# GET /Line/{id}/Route/Sequence/{direction}
# Returns: record<direction: string, isOutboundOnly: bool, lineId: string, lineName: string, lineStrings: list<string>, mode: string, orderedLineRoutes: table<name: string, naptanIds: list, serviceType: string>, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, stopPointSequences: table<branchId: int, direction: string, lineId: string, lineName: string, nextBranchIds: list, prevBranchIds: list, serviceType: string, stopPoint: list>>
# operationId: Line_RouteSequence
export def "line-route-sequence" [
  id: string
  direction: string@direction-completer
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
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
  --exclude-crowding: oneof<nothing, bool> # That excludes crowding from line disruptions. Can be true or false.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{id}/Route/Sequence/{direction}"
    path_params: [{name: id, var: id}, {name: direction, var: direction}]
    query: [{name: serviceTypes, var: service_types, style: multi}, {name: excludeCrowding, var: exclude_crowding}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, direction: $direction, service_types: $service_types, exclude_crowding: $exclude_crowding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of the stations that serve the given line id
#
# GET /Line/{id}/StopPoints
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: Line_StopPoints
export def "line-stop-points" [
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
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail line is requested, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Line/{id}/StopPoints"
    path_params: [{name: id, var: id}]
    query: [{name: tflOperatedNationalRailStationsOnly, var: tfl_operated_national_rail_stations_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, tfl_operated_national_rail_stations_only: $tfl_operated_national_rail_stations_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the timetable for a specified station on the give line
#
# GET /Line/{id}/Timetable/{fromStopPointId}
# Returns: record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>>
# operationId: Line_Timetable
export def "line-timetable" [
  id: string
  from_stop_point_id: string
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
    path: "/Line/{id}/Timetable/{fromStopPointId}"
    path_params: [{name: id, var: id}, {name: fromStopPointId, var: from_stop_point_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, from_stop_point_id: $from_stop_point_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the timetable for a specified station on the give line with specified destination
#
# GET /Line/{id}/Timetable/{fromStopPointId}/to/{toStopPointId}
# Returns: record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>>
# operationId: Line_TimetableTo
export def "line-timetable-to" [
  id: string
  from_stop_point_id: string
  to_stop_point_id: string
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
    path: "/Line/{id}/Timetable/{fromStopPointId}/to/{toStopPointId}"
    path_params: [{name: id, var: id}, {name: fromStopPointId, var: from_stop_point_id}, {name: toStopPointId, var: to_stop_point_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, from_stop_point_id: $from_stop_point_id, to_stop_point_id: $to_stop_point_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the service type active for a mode. Currently only supports tube
#
# GET /Mode/ActiveServiceTypes
# Returns: table<mode: string, serviceType: string>
# operationId: Mode_GetActiveServiceTypes
export def "mode-get-active-service-types" [
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
    path: "/Mode/ActiveServiceTypes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the next arrival predictions for all stops of a given mode
#
# GET /Mode/{mode}/Arrivals
# Returns: table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>
# operationId: Mode_Arrivals
export def "mode-arrivals" [
  mode: string
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
  --count: int # A number of arrivals to return for each stop, -1 to return all available. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Mode/{mode}/Arrivals"
    path_params: [{name: mode, var: mode}]
    query: [{name: count, var: count}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    mode: $mode, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the occupancy for bike points.
#
# GET /Occupancy/BikePoints/{ids}
# Returns: table<bikesCount: int, eBikesCount: int, emptyDocks: int, id: string, name: string, standardBikesCount: int, totalDocks: int>
# operationId: Occupancy_GetBikePointsOccupancies
export def "occupancy-get-bike-points-occupancies" [
  ids: list<string>
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
    path: "/Occupancy/BikePoints/{ids}"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the occupancy for all car parks that have occupancy data
#
# GET /Occupancy/CarPark
# Returns: table<bays: list<record>, carParkDetailsUrl: string, id: string, name: string>
export def "get-occupancy-car-park" [
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
    path: "/Occupancy/CarPark"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the occupancy for a car park with a given id
#
# GET /Occupancy/CarPark/{id}
# Returns: record<bays: table<bayCount: int, bayType: string, free: int, occupied: int>, carParkDetailsUrl: string, id: string, name: string>
# operationId: Occupancy_Get
export def "occupancy-get" [
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
    path: "/Occupancy/CarPark/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the occupancy for all charge connectors
#
# GET /Occupancy/ChargeConnector
# Returns: table<id: int, sourceSystemPlaceId: string, status: string>
# operationId: Occupancy_GetAllChargeConnectorStatus
export def "occupancy-get-all-charge-connector-status" [
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
    path: "/Occupancy/ChargeConnector"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the occupancy for a charge connectors with a given id (sourceSystemPlaceId)
#
# GET /Occupancy/ChargeConnector/{ids}
# Returns: table<id: int, sourceSystemPlaceId: string, status: string>
# operationId: Occupancy_GetChargeConnectorStatus
export def "occupancy-get-charge-connector-status" [
  ids: list<string>
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
    path: "/Occupancy/ChargeConnector/{ids}"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the places that lie within a geographic region. The geographic region of interest can either be specified by using a lat/lon geo-point and a radius in metres to return places within the locus defined by the lat/lon of its centre or alternatively, by the use of a bounding box defined by the lat/lon of its north-west and south-east corners. Optionally filters on type and can strip properties for a smaller payload.
#
# GET /Place
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: Place_GetByGeo
export def "place-get-by-geo" [
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
  --radius: float # The radius of the bounding circle in metres when only lat/lon are specified. (format: double)
  --categories: list<string> # An optional list of comma separated property categories to return in the Place's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /Place/Meta/categories endpoint)
  --include-children: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
  --type: list<string> # Place types to filter on, or null to return all types
  --active-only: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
  --number-of-places-to-return: int # If specified, limits the number of returned places equal to the given value (format: int32)
  --place-geo-sw-lat: float # format: double
  --place-geo-sw-lon: float # format: double
  --place-geo-ne-lat: float # format: double
  --place-geo-ne-lon: float # format: double
  --place-geo-lat: float # format: double
  --place-geo-lon: float # format: double
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Place"
    query: [{name: radius, var: radius}, {name: categories, var: categories, style: multi}, {name: includeChildren, var: include_children}, {name: type, var: type, style: multi}, {name: activeOnly, var: active_only}, {name: numberOfPlacesToReturn, var: number_of_places_to_return}, {name: "placeGeo.swLat", var: place_geo_sw_lat}, {name: "placeGeo.swLon", var: place_geo_sw_lon}, {name: "placeGeo.neLat", var: place_geo_ne_lat}, {name: "placeGeo.neLon", var: place_geo_ne_lon}, {name: "placeGeo.lat", var: place_geo_lat}, {name: "placeGeo.lon", var: place_geo_lon}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    radius: $radius, categories: $categories, include_children: $include_children, type: $type, active_only: $active_only, number_of_places_to_return: $number_of_places_to_return, place_geo_sw_lat: $place_geo_sw_lat, place_geo_sw_lon: $place_geo_sw_lon, place_geo_ne_lat: $place_geo_ne_lat, place_geo_ne_lon: $place_geo_ne_lon, place_geo_lat: $place_geo_lat, place_geo_lon: $place_geo_lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the set of streets associated with a post code.
#
# GET /Place/Address/Streets/{Postcode}
# Returns: record
# operationId: Place_GetStreetsByPostCode
export def "place-get-streets-by-post-code" [
  postcode: string
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
  --qp-postcode: string # required (spec name: postcode)
  --postcode-input-postcode: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Place/Address/Streets/{Postcode}"
    path_params: [{name: Postcode, var: postcode}]
    query: [{name: postcode, var: qp_postcode, required: true}, {name: "postcodeInput.postcode", var: postcode_input_postcode}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    postcode: $postcode, qp_postcode: $qp_postcode, postcode_input_postcode: $postcode_input_postcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of all of the available place property categories and keys.
#
# GET /Place/Meta/Categories
# Returns: table<availableKeys: list<string>, category: string>
# operationId: Place_MetaCategories
export def "place-meta-categories" [
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
    path: "/Place/Meta/Categories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of the available types of Place.
#
# GET /Place/Meta/PlaceTypes
# Returns: table<availableKeys: list<string>, category: string>
# operationId: Place_MetaPlaceTypes
export def "place-meta-place-types" [
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
    path: "/Place/Meta/PlaceTypes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all places that matches the given query
#
# GET /Place/Search
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: Place_Search
export def "place-search" [
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
  --name: string # The name of the place, you can use the /Place/Types/{types} endpoint to get a list of places for a given type including their names. (required)
  --types: list<string> # A comma-separated list of the types to return. Max. approx 12 types.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Place/Search"
    query: [{name: name, var: name, required: true}, {name: types, var: types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    name: $name, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all places of a given type
#
# GET /Place/Type/{types}
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: Place_GetByType
export def "place-get-by-type" [
  types: list<string>
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
  --active-only: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Place/Type/{types}"
    path_params: [{name: types, var: types, encode: array}]
    query: [{name: activeOnly, var: active_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    types: $types, active_only: $active_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the place with the given id.
#
# GET /Place/{id}
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: Place_Get
export def "place-get" [
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
  --include-children: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Place/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: includeChildren, var: include_children}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, include_children: $include_children
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets any places of the given type whose geography intersects the given latitude and longitude. In practice this means the Place must be polygonal e.g. a BoroughBoundary.
#
# GET /Place/{type}/At/{Lat}/{Lon}
# Returns: record
# operationId: Place_GetAt
export def "place-get-at" [
  type: list<string>
  lat: string
  lon: string
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
  --qp-lat: string # required (spec name: lat)
  --qp-lon: string # required (spec name: lon)
  --location-lat: float # required, format: double
  --location-lon: float # required, format: double
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Place/{type}/At/{Lat}/{Lon}"
    path_params: [{name: type, var: type, encode: array}, {name: Lat, var: lat}, {name: Lon, var: lon}]
    query: [{name: lat, var: qp_lat, required: true}, {name: lon, var: qp_lon, required: true}, {name: "location.lat", var: location_lat, required: true}, {name: "location.lon", var: location_lon, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    type: $type, lat: $lat, lon: $lon, qp_lat: $qp_lat, qp_lon: $qp_lon, location_lat: $location_lat, location_lon: $location_lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the place overlay for a given set of co-ordinates and a given width/height.
#
# GET /Place/{type}/overlay/{z}/{Lat}/{Lon}/{width}/{height}
# Returns: record
# operationId: Place_GetOverlay
export def "place-get-overlay" [
  type: list<string>
  z: int
  lat: string
  lon: string
  width: int
  height: int
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
  --qp-lat: string # required (spec name: lat)
  --qp-lon: string # required (spec name: lon)
  --location-lat: float # required, format: double
  --location-lon: float # required, format: double
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Place/{type}/overlay/{z}/{Lat}/{Lon}/{width}/{height}"
    path_params: [{name: type, var: type, encode: array}, {name: z, var: z}, {name: Lat, var: lat}, {name: Lon, var: lon}, {name: width, var: width}, {name: height, var: height}]
    query: [{name: lat, var: qp_lat, required: true}, {name: lon, var: qp_lon, required: true}, {name: "location.lat", var: location_lat, required: true}, {name: "location.lon", var: location_lon, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    type: $type, z: $z, lat: $lat, lon: $lon, width: $width, height: $height, qp_lat: $qp_lat, qp_lon: $qp_lon, location_lat: $location_lat, location_lon: $location_lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all roads managed by TfL
#
# GET /Road
# Returns: table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>
# operationId: Road_Get
export def "road-get" [
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
    path: "/Road"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid RoadDisruption categories
#
# GET /Road/Meta/Categories
# Returns: list<string>
# operationId: Road_MetaCategories
export def "road-meta-categories" [
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
    path: "/Road/Meta/Categories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of valid RoadDisruption severity codes
#
# GET /Road/Meta/Severities
# Returns: table<description: string, modeName: string, severityLevel: int>
# operationId: Road_MetaSeverities
export def "road-meta-severities" [
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
    path: "/Road/Meta/Severities"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of active disruptions filtered by disruption Ids.
#
# GET /Road/all/Disruption/{disruptionIds}
# Returns: record<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, geometry: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: table<endTime: string, startTime: string>, roadDisruptionImpactAreas: table<endDate: string, endTime: string, id: int, polygon: record, roadDisruptionId: string, startDate: string, startTime: string>, roadDisruptionLines: table<endDate: string, endTime: string, id: int, isDiversion: bool, multiLineString: record, roadDisruptionId: string, startDate: string, startTime: string>, roadProject: record<boroughsBenefited: list<string>, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: table<closure: string, directions: string, name: string, segments: list, sourceSystemId: int, sourceSystemKey: string>, subCategory: string, timeFrame: string, url: string>
# operationId: Road_DisruptionById
export def "road-disruption-by-id" [
  disruption_ids: list<string>
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
  --strip-content: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location and comments.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Road/all/Disruption/{disruptionIds}"
    path_params: [{name: disruptionIds, var: disruption_ids, encode: array}]
    query: [{name: stripContent, var: strip_content}]
    accept: ["application/geo+json", "application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    disruption_ids: $disruption_ids, strip_content: $strip_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of disrupted streets. If no date filters are provided, current disruptions are returned.
#
# GET /Road/all/Street/Disruption
# Returns: record
# operationId: Road_DisruptedStreets
export def "road-disrupted-streets" [
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
  --start-date: string # Optional, the start time to filter on. (required, format: date-time)
  --end-date: string # Optional, The end time to filter on. (required, format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Road/all/Street/Disruption"
    query: [{name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the road with the specified id (e.g. A1)
#
# GET /Road/{ids}
# Returns: table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>
export def "get-road-ids" [
  ids: list<string>
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
    path: "/Road/{ids}"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get active disruptions, filtered by road ids
#
# GET /Road/{ids}/Disruption
# Returns: table<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record>, geometry: record<geography: record>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: list<record>, roadDisruptionImpactAreas: list<record>, roadDisruptionLines: list<record>, roadProject: record<boroughsBenefited: list, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: list<record>, subCategory: string, timeFrame: string, url: string>
# operationId: Road_Disruption
export def "road-disruption" [
  ids: list<string>
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
  --strip-content: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location, comments and streets
  --severities: list<string> # an optional list of Severity names to filter on (a valid list of severities can be obtained from the /Road/Meta/severities endpoint)
  --categories: list<string> # an optional list of category names to filter on (a valid list of categories can be obtained from the /Road/Meta/categories endpoint)
  --closures: oneof<nothing, bool> # Optional, defaults to true. When true, always includes disruptions that have road closures, regardless of the severity filter. When false, the severity filter works as normal.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Road/{ids}/Disruption"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: stripContent, var: strip_content}, {name: severities, var: severities, style: multi}, {name: categories, var: categories, style: multi}, {name: closures, var: closures}]
    accept: ["application/geo+json", "application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, strip_content: $strip_content, severities: $severities, categories: $categories, closures: $closures
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the specified roads with the status aggregated over the date range specified, or now until the end of today if no dates are passed.
#
# GET /Road/{ids}/Status
# Returns: table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string>
# operationId: Road_Status
export def "road-status" [
  ids: list<string>
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
  --date-range-nullable-start-date: string # format: date-time
  --date-range-nullable-end-date: string # format: date-time
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Road/{ids}/Status"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: "dateRangeNullable.startDate", var: date_range_nullable_start_date}, {name: "dateRangeNullable.endDate", var: date_range_nullable_end_date}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, date_range_nullable_start_date: $date_range_nullable_start_date, date_range_nullable_end_date: $date_range_nullable_end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search the site for occurrences of the query string. The maximum number of results returned is equal to the maximum page size of 100. To return subsequent pages, use the paginated overload.
#
# GET /Search
# Returns: record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>
# operationId: Search_Get
export def "search-get" [
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
  --query: string # The search query (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Search"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Searches the bus schedules folder on S3 for a given bus number.
#
# GET /Search/BusSchedules
# Returns: record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>
# operationId: Search_BusSchedules
export def "search-bus-schedules" [
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
  --query: string # The search query (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Search/BusSchedules"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the available search categories.
#
# GET /Search/Meta/Categories
# Returns: list<string>
# operationId: Search_MetaCategories
export def "search-meta-categories" [
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
    path: "/Search/Meta/Categories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the available searchProvider names.
#
# GET /Search/Meta/SearchProviders
# Returns: list<string>
# operationId: Search_MetaSearchProviders
export def "search-meta-search-providers" [
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
    path: "/Search/Meta/SearchProviders"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the available sorting options.
#
# GET /Search/Meta/Sorts
# Returns: list<string>
# operationId: Search_MetaSorts
export def "search-meta-sorts" [
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
    path: "/Search/Meta/Sorts"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of StopPoints within {radius} by the specified criteria
#
# GET /StopPoint
# Returns: record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int>
# operationId: StopPoint_GetByGeoPoint
export def "stop-point-get-by-geo-point" [
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
  --stop-types: list<string> # a list of stopTypes that should be returned (a list of valid stop types can be obtained from the StopPoint/meta/stoptypes endpoint) (required)
  --radius: int # the radius of the bounding circle in metres (default : 200) (format: int32)
  --use-stop-point-hierarchy: oneof<nothing, bool> # Re-arrange the output into a parent/child hierarchy
  --modes: list<string> # the list of modes to search (comma separated mode names e.g. tube,dlr)
  --categories: list<string> # an optional list of comma separated property categories to return in the StopPoint's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /StopPoint/Meta/categories endpoint)
  --return-lines: oneof<nothing, bool> # true to return the lines that each stop point serves as a nested resource
  --location-lat: float # required, format: double
  --location-lon: float # required, format: double
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint"
    query: [{name: stopTypes, var: stop_types, style: multi, required: true}, {name: radius, var: radius}, {name: useStopPointHierarchy, var: use_stop_point_hierarchy}, {name: modes, var: modes, style: multi}, {name: categories, var: categories, style: multi}, {name: returnLines, var: return_lines}, {name: "location.lat", var: location_lat, required: true}, {name: "location.lon", var: location_lon, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    stop_types: $stop_types, radius: $radius, use_stop_point_hierarchy: $use_stop_point_hierarchy, modes: $modes, categories: $categories, return_lines: $return_lines, location_lat: $location_lat, location_lon: $location_lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of available StopPoint additional information categories
#
# GET /StopPoint/Meta/Categories
# Returns: table<availableKeys: list<string>, category: string>
# operationId: StopPoint_MetaCategories
export def "stop-point-meta-categories" [
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
    path: "/StopPoint/Meta/Categories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of available StopPoint modes
#
# GET /StopPoint/Meta/Modes
# Returns: table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string>
# operationId: StopPoint_MetaModes
export def "stop-point-meta-modes" [
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
    path: "/StopPoint/Meta/Modes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of available StopPoint types
#
# GET /StopPoint/Meta/StopTypes
# Returns: list<string>
# operationId: StopPoint_MetaStopTypes
export def "stop-point-meta-stop-types" [
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
    path: "/StopPoint/Meta/StopTypes"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of StopPoints filtered by the modes available at that StopPoint.
#
# GET /StopPoint/Mode/{modes}
# Returns: record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int>
# operationId: StopPoint_GetByMode
export def "stop-point-get-by-mode" [
  modes: list<string>
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
  --page: int # The data set page to return. Page 1 equates to the first 1000 stop points, page 2 equates to 1001-2000 etc. Must be entered for bus mode as data set is too large. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/Mode/{modes}"
    path_params: [{name: modes, var: modes, encode: array}]
    query: [{name: page, var: page}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a distinct list of disrupted stop points for the given modes
#
# GET /StopPoint/Mode/{modes}/Disruption
# Returns: table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string>
# operationId: StopPoint_DisruptionByMode
export def "stop-point-disruption-by-mode" [
  modes: list<string>
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
  --include-route-blocked-stops: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/Mode/{modes}/Disruption"
    path_params: [{name: modes, var: modes, encode: array}]
    query: [{name: includeRouteBlockedStops, var: include_route_blocked_stops}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    modes: $modes, include_route_blocked_stops: $include_route_blocked_stops
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search StopPoints by their common name, or their 5-digit Countdown Bus Stop Code.
#
# GET /StopPoint/Search
# Returns: record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>
export def "get-stop-point-search" [
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
  --query: string # The query string, case-insensitive. Leading and trailing wildcards are applied automatically. (required)
  --modes: list<string> # An optional, parameter separated list of the modes to filter by
  --fares-only: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --max-results: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches, it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list<string> # An optional, parameter separated list of the lines to filter by
  --include-hubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/Search"
    query: [{name: query, var: query, required: true}, {name: modes, var: modes, style: multi}, {name: faresOnly, var: fares_only}, {name: maxResults, var: max_results}, {name: lines, var: lines, style: multi}, {name: includeHubs, var: include_hubs}, {name: tflOperatedNationalRailStationsOnly, var: tfl_operated_national_rail_stations_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query, modes: $modes, fares_only: $fares_only, max_results: $max_results, lines: $lines, include_hubs: $include_hubs, tfl_operated_national_rail_stations_only: $tfl_operated_national_rail_stations_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search StopPoints by their common name, or their 5-digit Countdown Bus Stop Code.
#
# GET /StopPoint/Search/{query}
# Returns: record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int>
# operationId: StopPoint_Search
export def "stop-point-search" [
  query: string
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
  --modes: list<string> # An optional, parameter separated list of the modes to filter by
  --fares-only: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --max-results: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches, it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list<string> # An optional, parameter separated list of the lines to filter by
  --include-hubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/Search/{query}"
    path_params: [{name: query, var: query}]
    query: [{name: modes, var: modes, style: multi}, {name: faresOnly, var: fares_only}, {name: maxResults, var: max_results}, {name: lines, var: lines, style: multi}, {name: includeHubs, var: include_hubs}, {name: tflOperatedNationalRailStationsOnly, var: tfl_operated_national_rail_stations_only}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    query: $query, modes: $modes, fares_only: $fares_only, max_results: $max_results, lines: $lines, include_hubs: $include_hubs, tfl_operated_national_rail_stations_only: $tfl_operated_national_rail_stations_only
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the service types for a given stoppoint
#
# GET /StopPoint/ServiceTypes
# Returns: table<lineName: string, lineSpecificServiceTypes: list<record>>
# operationId: StopPoint_GetServiceTypes
export def "stop-point-get-service-types" [
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
  --id: string # The Naptan id of the stop (required)
  --line-ids: list<string> # The lines which contain the given Naptan id (all lines relevant to the given stoppoint if empty)
  --modes: list<string> # The modes which the lines are relevant to (all if empty)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/ServiceTypes"
    query: [{name: id, var: id, required: true}, {name: lineIds, var: line_ids, style: multi}, {name: modes, var: modes, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, line_ids: $line_ids, modes: $modes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a StopPoint for a given sms code.
#
# GET /StopPoint/Sms/{id}
# Returns: record
# operationId: StopPoint_GetBySms
export def "stop-point-get-by-sms" [
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
  --output: string # If set to "web", a 302 redirect to relevant website bus stop page is returned. Valid values are : web. All other values are ignored.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/Sms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: output, var: output}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, output: $output
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all stop points of a given type
#
# GET /StopPoint/Type/{types}
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: StopPoint_GetByType
export def "stop-point-get-by-type" [
  types: list<string>
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
    path: "/StopPoint/Type/{types}"
    path_params: [{name: types, var: types, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all the stop points of given type(s) with a page number
#
# GET /StopPoint/Type/{types}/page/{page}
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: StopPoint_GetByTypeWithPagination
export def "stop-point-get-by-type-with-pagination" [
  types: list<string>
  page: int
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
    path: "/StopPoint/Type/{types}/page/{page}"
    path_params: [{name: types, var: types, encode: array}, {name: page, var: page}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    types: $types, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of StopPoints corresponding to the given list of stop ids.
#
# GET /StopPoint/{ids}
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: StopPoint_Get
export def "stop-point-get" [
  ids: list<string>
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
  --include-crowding-data: oneof<nothing, bool> # Include the crowding data (static). To Filter further use: /StopPoint/{ids}/Crowding/{line}
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{ids}"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: includeCrowdingData, var: include_crowding_data}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, include_crowding_data: $include_crowding_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all disruptions for the specified StopPointId, plus disruptions for any child Naptan records it may have.
#
# GET /StopPoint/{ids}/Disruption
# Returns: table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string>
# operationId: StopPoint_Disruption
export def "stop-point-disruption" [
  ids: list<string>
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
  --get-family: oneof<nothing, bool> # Specify true to return disruptions for entire family, or false to return disruptions for just this stop point. Defaults to false.
  --include-route-blocked-stops: oneof<nothing, bool>
  --flatten-response: oneof<nothing, bool> # Specify true to associate all disruptions with parent stop point. (Only applicable when getFamily is true).
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{ids}/Disruption"
    path_params: [{name: ids, var: ids, encode: array}]
    query: [{name: getFamily, var: get_family}, {name: includeRouteBlockedStops, var: include_route_blocked_stops}, {name: flattenResponse, var: flatten_response}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids, get_family: $get_family, include_route_blocked_stops: $include_route_blocked_stops, flatten_response: $flatten_response
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of arrival and departure predictions for the given stop point id (overground, Elizabeth line and thameslink only)
#
# GET /StopPoint/{id}/ArrivalDepartures
# Returns: table<cause: string, departureStatus: string, destinationName: string, destinationNaptanId: string, estimatedTimeOfArrival: string, estimatedTimeOfDeparture: string, minutesAndSecondsToArrival: string, minutesAndSecondsToDeparture: string, naptanId: string, platformName: string, scheduledTimeOfArrival: string, scheduledTimeOfDeparture: string, stationName: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>>
# operationId: StopPoint_ArrivalDepartures
export def "stop-point-arrival-departures" [
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
  --line-ids: list<string> # A comma-separated list of line ids e.g. elizabeth, london-overground, thameslink (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{id}/ArrivalDepartures"
    path_params: [{name: id, var: id}]
    query: [{name: lineIds, var: line_ids, style: multi, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, line_ids: $line_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of arrival predictions for the given stop point id
#
# GET /StopPoint/{id}/Arrivals
# Returns: table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>
# operationId: StopPoint_Arrivals
export def "stop-point-arrivals" [
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
    path: "/StopPoint/{id}/Arrivals"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets Stopoints that are reachable from a station/line combination.
#
# GET /StopPoint/{id}/CanReachOnLine/{lineId}
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: StopPoint_ReachableFrom
export def "stop-point-reachable-from" [
  id: string
  line_id: string
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
  --service-types: list<string> # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{id}/CanReachOnLine/{lineId}"
    path_params: [{name: id, var: id}, {name: lineId, var: line_id}]
    query: [{name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, line_id: $line_id, service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all the Crowding data (static) for the StopPointId, plus crowding data for a given line and optionally a particular direction.
#
# GET /StopPoint/{id}/Crowding/{line}
# Returns: table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>
# operationId: StopPoint_Crowding
export def "stop-point-crowding" [
  id: string
  line: string
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
  --direction: string@direction-completer # The direction of travel. Can be inbound or outbound. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{id}/Crowding/{line}"
    path_params: [{name: id, var: id}, {name: line, var: line}]
    query: [{name: direction, var: direction, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, line: $line, direction: $direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the canonical direction, "inbound" or "outbound", for a given pair of stop point Ids in the direction from -> to.
#
# GET /StopPoint/{id}/DirectionTo/{toStopPointId}
# Returns: string
# operationId: StopPoint_Direction
export def "stop-point-direction" [
  id: string
  to_stop_point_id: string
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
  --line-id: string # Optional line id filter e.g. victoria
]: nothing -> any {
  http-request {
    method: get
    path: "/StopPoint/{id}/DirectionTo/{toStopPointId}"
    path_params: [{name: id, var: id}, {name: toStopPointId, var: to_stop_point_id}]
    query: [{name: lineId, var: line_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, to_stop_point_id: $to_stop_point_id, line_id: $line_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the route sections for all the lines that service the given stop point ids
#
# GET /StopPoint/{id}/Route
# Returns: table<destinationName: string, direction: string, isActive: bool, lineId: string, lineString: string, mode: string, naptanId: string, routeSectionName: string, serviceType: string, validFrom: string, validTo: string, vehicleDestinationText: string>
# operationId: StopPoint_Route
export def "stop-point-route" [
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
  --service-types: list<string> # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{id}/Route"
    path_params: [{name: id, var: id}]
    query: [{name: serviceTypes, var: service_types, style: multi}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, service_types: $service_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of places corresponding to a given id and place types.
#
# GET /StopPoint/{id}/placeTypes
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
export def "get-stop-point-id-place-types" [
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
  --place-types: list<string> # A comcomma-separated value representing the place types. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/StopPoint/{id}/placeTypes"
    path_params: [{name: id, var: id}]
    query: [{name: placeTypes, var: place_types, style: multi, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    id: $id, place_types: $place_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get car parks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/CarParks
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: StopPoint_GetCarParksById
export def "stop-point-get-car-parks-by-id" [
  stop_point_id: string
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
    path: "/StopPoint/{stopPointId}/CarParks"
    path_params: [{name: stopPointId, var: stop_point_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    stop_point_id: $stop_point_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of taxi ranks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/TaxiRanks
# Returns: table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string>
# operationId: StopPoint_GetTaxiRanksByIds
export def "stop-point-get-taxi-ranks-by-ids" [
  stop_point_id: string
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
    path: "/StopPoint/{stopPointId}/TaxiRanks"
    path_params: [{name: stopPointId, var: stop_point_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    stop_point_id: $stop_point_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/compareOverlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# Returns: record
# operationId: TravelTime_GetCompareOverlay
export def "travel-time-get-compare-overlay" [
  z: int
  map_center_lat: float
  map_center_lon: float
  pin_lat: float
  pin_lon: float
  width: int
  height: int
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
  --scenario-title: string # The title of the scenario. (required)
  --time-of-day-id: string # The id for the time of day (AM/INTER/PM) (required)
  --mode-id: string # The id of the mode. (required)
  --direction: string@direction-completer-1 # The direction of travel. (required)
  --travel-time-interval: int # The total minutes between the travel time bands (required, format: int32)
  --compare-type: string # required
  --compare-value: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TravelTimes/compareOverlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}"
    path_params: [{name: z, var: z}, {name: mapCenterLat, var: map_center_lat}, {name: mapCenterLon, var: map_center_lon}, {name: pinLat, var: pin_lat}, {name: pinLon, var: pin_lon}, {name: width, var: width}, {name: height, var: height}]
    query: [{name: scenarioTitle, var: scenario_title, required: true}, {name: timeOfDayId, var: time_of_day_id, required: true}, {name: modeId, var: mode_id, required: true}, {name: direction, var: direction, required: true}, {name: travelTimeInterval, var: travel_time_interval, required: true}, {name: compareType, var: compare_type, required: true}, {name: compareValue, var: compare_value, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    z: $z, map_center_lat: $map_center_lat, map_center_lon: $map_center_lon, pin_lat: $pin_lat, pin_lon: $pin_lon, width: $width, height: $height, scenario_title: $scenario_title, time_of_day_id: $time_of_day_id, mode_id: $mode_id, direction: $direction, travel_time_interval: $travel_time_interval, compare_type: $compare_type, compare_value: $compare_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/overlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# Returns: record
# operationId: TravelTime_GetOverlay
export def "travel-time-get-overlay" [
  z: int
  map_center_lat: float
  map_center_lon: float
  pin_lat: float
  pin_lon: float
  width: int
  height: int
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
  --scenario-title: string # The title of the scenario. (required)
  --time-of-day-id: string # The id for the time of day (AM/INTER/PM) (required)
  --mode-id: string # The id of the mode. (required)
  --direction: string@direction-completer-1 # The direction of travel. (required)
  --travel-time-interval: int # The total minutes between the travel time bands (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TravelTimes/overlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}"
    path_params: [{name: z, var: z}, {name: mapCenterLat, var: map_center_lat}, {name: mapCenterLon, var: map_center_lon}, {name: pinLat, var: pin_lat}, {name: pinLon, var: pin_lon}, {name: width, var: width}, {name: height, var: height}]
    query: [{name: scenarioTitle, var: scenario_title, required: true}, {name: timeOfDayId, var: time_of_day_id, required: true}, {name: modeId, var: mode_id, required: true}, {name: direction, var: direction, required: true}, {name: travelTimeInterval, var: travel_time_interval, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    z: $z, map_center_lat: $map_center_lat, map_center_lon: $map_center_lon, pin_lat: $pin_lat, pin_lon: $pin_lon, width: $width, height: $height, scenario_title: $scenario_title, time_of_day_id: $time_of_day_id, mode_id: $mode_id, direction: $direction, travel_time_interval: $travel_time_interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the predictions for a given list of vehicle Id's.
#
# GET /Vehicle/{ids}/Arrivals
# Returns: table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string>
# operationId: Vehicle_Get
export def "vehicle-get" [
  ids: list<string>
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
    path: "/Vehicle/{ids}/Arrivals"
    path_params: [{name: ids, var: ids, encode: array}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: query-app_key
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
