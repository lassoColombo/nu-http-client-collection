# Auto-generated client for Viator API Documentation &amp; Specification – Merchant Partners v1.0.0
# Source: https://api.apis.guru/v2/specs/viator.com/1.0.0/openapi.json
# Auth: --token flag or $env.VIATOR_API_DOCUMENTATION_AMP_SPECIFICATION_MERCHANT_PARTNERS_TOKEN

const CLIENT = {
  base_url: "https://viatorapi.viator.com/service"
  token_env_var: "VIATOR_API_DOCUMENTATION_AMP_SPECIFICATION_MERCHANT_PARTNERS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: exp-api-key, in: header, header_name: exp-api-key, prefix: ""}
    {name: query-apiKey, in: query, header_name: apiKey, prefix: ""}
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

def base-url-completer [] { ["https://viatorapi.viator.com/service" "https://viatorapi.sandbox.viator.com/service" "https://api.sandbox.viator.com/partner"] }
def auth-scheme-completer [] { ["exp-api-key" "query-apiKey"] }

# Completers for enum parameters
def sort-order-completer [] { ["REVIEW_RATING_A" "REVIEW_RATING_D" "REVIEW_RATING_SUBMISSION_DATE_D"] }
def voucher-option-completer [] { ["VOUCHER_E" "VOUCHER_PAPER_ONLY"] }
def sort-order-completer-1 [] { ["PRICE_FROM_A" "PRICE_FROM_D" "REVIEW_AVG_RATING_A" "REVIEW_AVG_RATING_D" "TOP_SELLERS"] }
def sort-order-completer-2 [] { ["SEO_ALPHABETICAL" "SEO_PUBLISHED_DATE_A" "SEO_PUBLISHED_DATE_D" "SEO_REVIEW_AVG_RATING_A" "SEO_REVIEW_AVG_RATING_D"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    available-products: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpFormatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>"
    booking-availability: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<availability: list<record>, firstAvailableDate: string, lastAvailableDate: string, productCode: string>>"
    booking-availability-dates: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record>"
    booking-availability-tourgrades: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBands: list, ageBandsRequired: list, available: bool, bookingDate: string, currencyCode: string, defaultLanguageCode: string, gradeCode: string, gradeDepartureTime: string, gradeDescription: string, gradeTitle: string, langServices: record, merchantNetPrice: float, merchantNetPriceFormatted: string, retailPrice: float, retailPriceFormatted: string, sortOrder: int, unavailableReason: string>>"
    booking-availability-tourgrades-pricingmatrix: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingMonth: string, dates: list<record>, pricingUnit: string>>"
    booking-book: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, omniPreRuleList: string, paypalRedirectURL: string, rulesApplied: string, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>"
    booking-calculateprice: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<currencyCode: string, hasPromoCode: bool, itinerary: record<bookerEmail: string, bookingDate: string, bookingStatus: record, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list, itineraryId: int, omniPreRuleList: int, paypalRedirectURL: string, rulesApplied: list, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: int, voucherKey: string, voucherURL: string>, itineraryFromPrice: float, itineraryFromPriceFormatted: string, itineraryNewPrice: float, itineraryNewPriceFormatted: string, itinerarySaving: int, itinerarySavingFormatted: string, paymentGatewayInfo: string, promoCode: string, promoCodeExpired: bool, promoCodeValid: bool, rulesApplied: list<string>>>"
    booking-hotels: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<address: string, brand: string, city: string, destinationId: int, hotelString: string, id: string, latitude: float, longitude: float, name: string, notes: string, phone: string, postcode: string, productCodes: list, sortOrder: int>>"
    booking-mybookings: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>"
    booking-pastbooking: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>"
    booking-pricingmatrix: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBandPrices: list, bookingDate: string, pricingUnit: string, sortOrder: int>>"
    booking-status: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, distributorRef: string, itemSummaries: list<record>, itineraryId: int, sortOrder: int>>"
    booking-status-items: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<bookingStatus: record, distributorItemRef: string, itemId: int>>"
    booking-voucher: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: string>"
    cancellation-reasons: "table<reasons: list<record>>"
    cancel-booking: "record<bookingId: string, reason: string, status: string>"
    cancel-booking-quote: "record<bookingId: string, refundDetails: record<currencyCode: string, itemPrice: float, refundAmount: float, refundPercentage: float>, status: string>"
    health-check: "record<allGood: bool, capiOk: bool, dbOk: bool, memcachedOk: bool, message: string>"
    merchant-cancellation: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<cancelItems: list<record>, distributorRef: string, itineraryId: int>>"
    product: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<additionalInfo: list<string>, admission: string, ageBands: list<record>, allTravellerNamesRequired: bool, applePassSupported: bool, available: bool, bookingEngineId: string, bookingQuestions: list<record>, catIds: list<int>, city: string, code: string, country: string, currencyCode: string, departurePoint: string, departureTime: string, departureTimeComments: string, description: string, destinationId: int, duration: string, essential: string, exclusions: list<string>, highlights: int, hotelPickup: bool, inclusions: list<string>, itinerary: string, location: string, mapURL: string, maxTravellerCount: int, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, merchantTermsAndConditions: record<amountRefundable: int, cancellationFromTourDate: list, merchantTermsAndConditionsType: int, termsAndConditions: string>, onRequestPeriod: int, onSale: bool, operates: string, panoramaCount: int, pas: record, passengerAttributes: list<record>, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productPhotos: list<record>, productUrlName: string, rating: float, ratingCounts: record<\"1\": float, \"2\": float, \"3\": float, \"4\": float, \"5\": float>, region: string, returnDetails: string, reviewCount: int, reviews: list<record>, rrp: int, rrpFormatted: string, salesPoints: list<string>, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, specialOffer: string, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list<int>, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, tourGrades: list<record>, tourGradesAvailable: bool, translationLevel: int, userPhotos: list<record>, videoCount: int, videos: string, voucherOption: string, voucherRequirements: any, webURL: string>>"
    product-photos: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<caption: string, editorsPick: bool, ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, photoHiResURL: string, photoId: int, photoMediumResURL: string, photoURL: string, productCode: string, productTitle: string, productUrlName: string, sortOrder: int, sslSupported: bool, thumbnailURL: string, timeUploaded: string, title: string>>"
    product-reviews: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, productCode: string, productTitle: string, productUrlName: string, publishedDate: string, rating: int, review: string, reviewId: int, sortOrder: int, sslSupported: bool, submissionDate: string, viatorFeedback: string, viatorNotes: string>>"
    search-freetext: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<searchType: string, sortOrder: int>>"
    search-products: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: int, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: any, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>"
    search-products-codes: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryGroupId: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>"
    taxonomy-attractions: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<attractionCity: string, attractionLatitude: float, attractionLongitude: float, attractionState: string, attractionStreetAddress: string, destinationId: int, pageUrlName: string, photoCount: int, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, productCount: int, publishedDate: string, rating: float, seoId: int, sortOrder: int, thumbnailHiResURL: string, thumbnailURL: string, title: string, webURL: string>>"
    taxonomy-categories: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<groupName: string, groupUrlName: string, id: int, productCount: int, subcategories: list, thumbnailURL: string>>"
    taxonomy-destinations: "record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<defaultCurrencyCode: string, destinationId: int, destinationName: string, destinationType: string, destinationUrlName: string, iataCode: string, latitude: float, longitude: float, lookupId: string, parentId: int, selectable: bool, sortOrder: int, timeZone: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["available-products" "booking-availability" "booking-availability-dates" "booking-availability-tourgrades" "booking-availability-tourgrades-pricingmatrix" "booking-book" "booking-calculateprice" "booking-hotels" "booking-mybookings" "booking-pastbooking" "booking-pricingmatrix" "booking-status" "booking-status-items" "booking-voucher" "cancellation-reasons" "cancel-booking" "cancel-booking-quote" "health-check" "merchant-cancellation" "product" "product-photos" "product-reviews" "search-freetext" "search-products" "search-products-codes" "taxonomy-attractions" "taxonomy-categories" "taxonomy-destinations" "commands"] | sort) } | get name | first)
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

# /available/products
#
# POST /available/products
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpFormatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>
# operationId: availableProducts
export def "available-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --currency-code: string # **currency** in which to display product pricing - default: `'USD'`
  --end-date: string # **end date** of the date range to search within (must be in the future)
  --num-adults: int # **number of adult travelers** who wish to participate - default: `1`
  --product-codes: list<string> # **array of unique alphanumeric product identifiers** specifying which products to find the availability of - maximum: `50` (e.g. [5010SYDNEY, 2280SUN, 9169P50])
  --start-date: string # **start date** of the date range to search within (must be in the future)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/available/products"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: currencyCode, var: currency_code}, {name: endDate, var: end_date}, {name: numAdults, var: num_adults}, {name: productCodes, var: product_codes}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, currency_code: $currency_code, end_date: $end_date, num_adults: $num_adults, product_codes: $product_codes, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/availability
#
# POST /booking/availability
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<availability: list<record>, firstAvailableDate: string, lastAvailableDate: string, productCode: string>>
# operationId: bookingAvailability
export def "booking-availability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --age-bands: list # **array of objects** specifying the age bands by which to to filter search results — item shape: {bandId?: int, count?: int}
  --currency-code: string # **currency code** for the currency in which to display tour grade pricing information
  --month: string # **month component** (text format) of the start of the date range for which to retrieve tour grade availability information (must be in the future)
  --product-code: string # **unique alphanumeric identifier** of the product for which you wish to retrieve tour grade availability information
  --year: string # **year component** (text format) of the start of the date range for which to retrieve tour grade availability information (must be in the future)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/availability"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ageBands, var: age_bands}, {name: currencyCode, var: currency_code}, {name: month, var: month}, {name: productCode, var: product_code}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, age_bands: $age_bands, currency_code: $currency_code, month: $month, product_code: $product_code, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/availability/dates
#
# GET /booking/availability/dates
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record>
# operationId: bookingAvailabilityDates
export def "booking-availability-dates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-code: string # **unique alphanumeric identifier** of the product (e.g. 2280AAHT)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/booking/availability/dates"
    query: [{name: productCode, var: product_code}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    product_code: $product_code, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/availability/tourgrades
#
# POST /booking/availability/tourgrades
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBands: list, ageBandsRequired: list, available: bool, bookingDate: string, currencyCode: string, defaultLanguageCode: string, gradeCode: string, gradeDepartureTime: string, gradeDescription: string, gradeTitle: string, langServices: record, merchantNetPrice: float, merchantNetPriceFormatted: string, retailPrice: float, retailPriceFormatted: string, sortOrder: int, unavailableReason: string>>
# operationId: bookingAvailabilityTourgrades
export def "booking-availability-tourgrades" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --age-bands: list # **array** of ageBand objects — item shape: {bandId?: int, count?: int}
  --booking-date: string # **date** to enquire about available tour grades for *this* product (must be in the future)
  --currency-code: string # **currency code** for the currency in which to display pricing information
  --product-code: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/availability/tourgrades"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ageBands, var: age_bands}, {name: bookingDate, var: booking_date}, {name: currencyCode, var: currency_code}, {name: productCode, var: product_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, age_bands: $age_bands, booking_date: $booking_date, currency_code: $currency_code, product_code: $product_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/availability/tourgrades/pricingmatrix
#
# POST /booking/availability/tourgrades/pricingmatrix
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingMonth: string, dates: list<record>, pricingUnit: string>>
# operationId: bookingAvailabilityTourgradesPricingmatrix
export def "booking-availability-tourgrades-pricingmatrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display pricing details
  --month: string # **month of year** (as text) by which to filter results (must be in the future)
  --product-code: string # **alphanumeric identifier** of product about which to retrieve tour grade and pricing information
  --year: string # **year** (as text) by which to filter results (must be in the future)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/availability/tourgrades/pricingmatrix"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: currencyCode, var: currency_code}, {name: month, var: month}, {name: productCode, var: product_code}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, currency_code: $currency_code, month: $month, product_code: $product_code, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/book
#
# POST /booking/book
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, omniPreRuleList: string, paypalRedirectURL: string, rulesApplied: string, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>
# operationId: bookingBook
export def "booking-book" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --booker: record # **object** containing details about the primary contact (**note**: this contact needn't be a traveller) — shape: {cellPhone?: string, cellPhoneCountryCode?: string, email?: string, firstname: string, homePhone?: string, surname: string, title?: string}
  --currency-code: string # **currency code** for the currency the booking will be submitted in (you will be billed in this currency)
  --demo: oneof<nothing, bool> # **specifier**: `true` if this is a *demo* booking only (demos do not send any notifications, are automatically confirmed and OnRequest products become freesale products. Default value is true. Production must have `demo` set to `false`.
  --items: list # **array** of items to be booked — item shape: {bookingQuestionAnswers?: list, hotelId?: string, languageOptionCode?: string, partnerItemDetail?: record, pickupPoint?: string, productCode?: string, specialRequirements?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
  --partner-detail: record # Applicable only for extra partner detail for either partner or merchant partner for sending partner specific information — shape: {distributorRef?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/book"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: booker, var: booker}, {name: currencyCode, var: currency_code}, {name: demo, var: demo}, {name: items, var: items}, {name: partnerDetail, var: partner_detail}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, booker: $booker, currency_code: $currency_code, demo: $demo, items: $items, partner_detail: $partner_detail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/calculateprice
#
# POST /booking/calculateprice
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<currencyCode: string, hasPromoCode: bool, itinerary: record<bookerEmail: string, bookingDate: string, bookingStatus: record, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list, itineraryId: int, omniPreRuleList: int, paypalRedirectURL: string, rulesApplied: list, securityToken: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: int, voucherKey: string, voucherURL: string>, itineraryFromPrice: float, itineraryFromPriceFormatted: string, itineraryNewPrice: float, itineraryNewPriceFormatted: string, itinerarySaving: int, itinerarySavingFormatted: string, paymentGatewayInfo: string, promoCode: string, promoCodeExpired: bool, promoCodeValid: bool, rulesApplied: list<string>>>
# operationId: bookingCalculateprice
export def "booking-calculateprice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display pricing details
  --items: list # **array** of travel detail objects — item shape: {productCode?: string, tourGradeCode?: string, travelDate?: string, travellers?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/calculateprice"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: currencyCode, var: currency_code}, {name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, currency_code: $currency_code, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/hotels
#
# GET /booking/hotels
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<address: string, brand: string, city: string, destinationId: int, hotelString: string, id: string, latitude: float, longitude: float, name: string, notes: string, phone: string, postcode: string, productCodes: list, sortOrder: int>>
# operationId: bookingHotels
export def "booking-hotels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-code: string # **unique alphanumeric identifier** of the product (e.g. 2280AAHT)
  --dest-id: int # **unique numeric identifier** of the destination (e.g. 123)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/booking/hotels"
    query: [{name: productCode, var: product_code}, {name: destId, var: dest_id}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    product_code: $product_code, dest_id: $dest_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/mybookings
#
# GET /booking/mybookings
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>
# operationId: bookingMybookings
export def "booking-mybookings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --voucher-key: string # **voucher key** for the booking (e.g. 3299307:93c7f36a56b18ba1068787ba7fb7988da5c8ad08db77604110141ff21498603e:600033670)
  --email: string # **email address** of the booker for the booking (e.g. apitest@viator.com)
  --itinerary-or-item-id: string # The booking reference number of the item - **Note**: For more information, see [Booking references](#section/Key-concepts/Booking-references) (e.g. 700179574)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/booking/mybookings"
    query: [{name: voucherKey, var: voucher_key}, {name: email, var: email}, {name: itineraryOrItemId, var: itinerary_or_item_id}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    voucher_key: $voucher_key, email: $email, itinerary_or_item_id: $itinerary_or_item_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/pastbooking
#
# GET /booking/pastbooking
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookerEmail: string, bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, currencyCode: string, distributorRef: string, exchangeRate: int, hasVoucher: bool, itemSummaries: list<record>, itineraryId: int, rulesApplied: string, sortOrder: int, totalPrice: float, totalPriceFormatted: string, totalPriceUSD: float, userId: string, voucherKey: string, voucherURL: string>>
# operationId: bookingPastbooking
export def "booking-pastbooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --voucher-key: string # **specifier** of past booking type (use *one* of: `itemId` (booking reference) *and* `'voucherKey'` *or* `'email'`) (e.g. 1005851866:4af44c13ecf3f1a7d3f9ef2fc00c2257e08fa42ae20f877f3039ff9b52aba24e:580669678)
  --email: string # **email address** by which to search for past bookings (e.g. apitest@viator.com)
  --item-id: string # Search for a booking with this **unique booking-reference number**. See [Booking references](#section/Key-concepts/Booking-references) for more information. (e.g. 580669678)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/booking/pastbooking"
    query: [{name: voucherKey, var: voucher_key}, {name: email, var: email}, {name: itemId, var: item_id}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    voucher_key: $voucher_key, email: $email, item_id: $item_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/pricingmatrix
#
# POST /booking/pricingmatrix
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ageBandPrices: list, bookingDate: string, pricingUnit: string, sortOrder: int>>
# operationId: bookingPricingmatrix
export def "booking-pricingmatrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --booking-date: string # **date** for which to retrieve pricing data (must be in the future) (**note**: this is an optional parameter for normal products; if the date is *not* provided then the nearest available date is determined)
  --currency-code: string # **currency code** of the currency in which to display pricing information
  --product-code: string # **unique alphanumeric identifier** of the product for which to retrieve the pricing matrix
  --tour-grade-code: string # **alphanumeric identifier** of the product tour grade for which to retrieve the pricing matrix
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/pricingmatrix"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: bookingDate, var: booking_date}, {name: currencyCode, var: currency_code}, {name: productCode, var: product_code}, {name: tourGradeCode, var: tour_grade_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, booking_date: $booking_date, currency_code: $currency_code, product_code: $product_code, tour_grade_code: $tour_grade_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/status
#
# POST /booking/status
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<bookingDate: string, bookingStatus: record<amended: bool, cancelled: bool, confirmed: bool, failed: bool, level: string, pending: bool, status: int, text: string, type: string>, distributorRef: string, itemSummaries: list<record>, itineraryId: int, sortOrder: int>>
# operationId: bookingStatus
export def "booking-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --booking-date-from: string # **earliest date** for *this* booking (must be in the future)
  --booking-date-to: string # **latest date** for *this* booking (must be in the future)
  --distributor-item-refs: list<string> # **array** of partner-defined distributor item reference identifiers e.g. `['refItem1','refItem2','refItem3']`
  --distributor-refs: list<string> # **array** of partner-defined distributor reference identifiers
  --item-ids: list<int> # **array** of item identifiers to check
  --lead-first-name: string # **first name** of the lead traveler
  --lead-surname: string # **surname** of the lead traveler
  --test: oneof<nothing, bool> # **specifier**: - `true`: bypass the poll limit in the prelive environment only (recommended for testing) - `false`: (default)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/status"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: bookingDateFrom, var: booking_date_from}, {name: bookingDateTo, var: booking_date_to}, {name: distributorItemRefs, var: distributor_item_refs}, {name: distributorRefs, var: distributor_refs}, {name: itemIds, var: item_ids}, {name: leadFirstName, var: lead_first_name}, {name: leadSurname, var: lead_surname}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, booking_date_from: $booking_date_from, booking_date_to: $booking_date_to, distributor_item_refs: $distributor_item_refs, distributor_refs: $distributor_refs, item_ids: $item_ids, lead_first_name: $lead_first_name, lead_surname: $lead_surname, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/status/items
#
# POST /booking/status/items
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<bookingStatus: record, distributorItemRef: string, itemId: int>>
# operationId: bookingStatusItems
export def "booking-status-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --booking-date-from: string # **earliest date** for when the booking(s) in question were made (must be in the future)
  --booking-date-to: string # **latest date** for when the booking(s) in question were made (must be in the future)
  --distributor-item-refs: list<string> # **array** of partner-defined distributor item reference identifiers e.g. `['refItem1','refItem2','refItem3']`
  --distributor-refs: list<string> # **array** of partner-defined distributor reference identifiers
  --item-ids: list<int> # **array** of booking-reference numbers to check `itemId` (booking-reference provided by Viator). For more information, see [Booking references](#section/Key-concepts/Booking-references)
  --lead-first-name: string # **first name** of the lead traveler
  --lead-surname: string # **surname** of the lead traveler
  --test: oneof<nothing, bool> # **specifier**: - `true`: bypass the poll limit in the prelive environment only - `false`: (default) make a *real* booking, not a test
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/booking/status/items"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: bookingDateFrom, var: booking_date_from}, {name: bookingDateTo, var: booking_date_to}, {name: distributorItemRefs, var: distributor_item_refs}, {name: distributorRefs, var: distributor_refs}, {name: itemIds, var: item_ids}, {name: leadFirstName, var: lead_first_name}, {name: leadSurname, var: lead_surname}, {name: test, var: test}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, booking_date_from: $booking_date_from, booking_date_to: $booking_date_to, distributor_item_refs: $distributor_item_refs, distributor_refs: $distributor_refs, item_ids: $item_ids, lead_first_name: $lead_first_name, lead_surname: $lead_surname, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /booking/voucher
#
# GET /booking/voucher
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: string>
# operationId: bookingVoucher
export def "booking-voucher" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lead-last-name: string # **surname** of *this* lead traveler (e.g. Simpson)
  --item-id: int # Booking-reference number generated by Viator - **Note**: For more information, see: [Booking references](#section/Key-concepts/Booking-references) (e.g. 600033670)
  --embedded-resources: oneof<nothing, bool> # ignore (Viator only) (e.g. false)
  --voucher-key: string # **identifier** for the voucher - **note**: use <u>either</u> `voucherKey` <u>or</u> the three separate parameters - if `voucherKey` is provided as well as the other parameters, then `voucherKey` overrides the other paramaters - `voucherKey` is obtained from [/booking/mybookings](#operation/bookingMybookings) or in the response from [/booking/book](#operation/bookingBook) when you make a booking (e.g. 3299307:93c7f36a56b18ba1068787ba7fb7988da5c8ad08db77604110141ff21498603e:600033670)
  --full-html: oneof<nothing, bool> # **specifier**: - set to `true` if you wish to retrieve the full HTML-formatted voucher - set to `false` if you want the div fragment (optional) (e.g. true)
  --mobile-voucher: oneof<nothing, bool> # **specifier**: - if set to `true`, the service returns the mobile (cut down) HTML-formatted voucher - if `false` the full voucher HTML is returned (ignoring `fullHTML`) - default: `true` - this field should only be enabled for products that have a `voucherOption` of `'VOUCHER_E'` - do not enable `mobileVouchers` for paper vouchers (`voucherOption` of `'VOUCHER_PAPER_ONLY'`) as no barcode is returned - the voucher information is available in the response from [/product](#operation/product), [/booking/book](#operation/bookingBook), [/booking/pastbooking](#operation/bookingPastbooking), [/booking/mybookings](#operation/bookingMybookings) (it is also displayed under the 'Redemption Info' heading in this service) (e.g. true)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/booking/voucher"
    query: [{name: leadLastName, var: lead_last_name}, {name: itemId, var: item_id}, {name: embeddedResources, var: embedded_resources}, {name: voucherKey, var: voucher_key}, {name: fullHTML, var: full_html}, {name: mobileVoucher, var: mobile_voucher}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    lead_last_name: $lead_last_name, item_id: $item_id, embedded_resources: $embedded_resources, voucher_key: $voucher_key, full_html: $full_html, mobile_voucher: $mobile_voucher, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /bookings/cancel-reasons
#
# GET /bookings/cancel-reasons
# Returns: table<reasons: list<record>>
# operationId: cancellationReasons
export def "cancellation-reasons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bookings/cancel-reasons"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.sandbox.viator.com/partner"
    auth: exp-api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /bookings/{booking-reference}/cancel
#
# POST /bookings/{booking-reference}/cancel
# Returns: record<bookingId: string, reason: string, status: string>
# operationId: cancelBooking
export def "cancel-booking" [
  booking_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --reason-code: string # Machine-interpretable identification code for this cancellation reason, retrieved from [cancellationReasons](#operation/cancellationReasons) (e.g. Customer_Service.I_canceled_my_entire_trip)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bookings/{booking-reference}/cancel"
    path_params: [{name: booking-reference, var: booking_reference}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: reasonCode, var: reason_code}]}
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.sandbox.viator.com/partner"
    auth: exp-api-key
  } {
    booking_reference: $booking_reference, accept_language: $accept_language, reason_code: $reason_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /bookings/{booking-reference}/cancel-quote
#
# GET /bookings/{booking-reference}/cancel-quote
# Returns: record<bookingId: string, refundDetails: record<currencyCode: string, itemPrice: float, refundAmount: float, refundPercentage: float>, status: string>
# operationId: cancelBookingQuote
export def "cancel-booking-quote" [
  booking_reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/bookings/{booking-reference}/cancel-quote"
    path_params: [{name: booking-reference, var: booking_reference}]
    accept: ["application/json"]
    ok: [200]
    base_url: "https://api.sandbox.viator.com/partner"
    auth: exp-api-key
  } {
    booking_reference: $booking_reference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /health/check
#
# GET /health/check
# Returns: record<allGood: bool, capiOk: bool, dbOk: bool, memcachedOk: bool, message: string>
# operationId: healthCheck
export def "health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health/check"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /merchant/cancellation
#
# POST /merchant/cancellation
# DEPRECATED
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<cancelItems: list<record>, distributorRef: string, itineraryId: int>>
# operationId: merchantCancellation
@deprecated
export def "merchant-cancellation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --cancel-items: list # **array** of objects detailing itinerary items to cancel — item shape: {cancelCode?: string, cancelDescription?: string, distributorItemRef?: string, itemId?: int}
  --distributor-ref: string # **itinerary reference identifier** (partner defined) for the booking to cancel (e.g. Jdp122)
  --itinerary-id: int # **numeric identifier** for the itinerary (e.g. 1234655)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/merchant/cancellation"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: cancelItems, var: cancel_items}, {name: distributorRef, var: distributor_ref}, {name: itineraryId, var: itinerary_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, cancel_items: $cancel_items, distributor_ref: $distributor_ref, itinerary_id: $itinerary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /product
#
# GET /product
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: record<additionalInfo: list<string>, admission: string, ageBands: list<record>, allTravellerNamesRequired: bool, applePassSupported: bool, available: bool, bookingEngineId: string, bookingQuestions: list<record>, catIds: list<int>, city: string, code: string, country: string, currencyCode: string, departurePoint: string, departureTime: string, departureTimeComments: string, description: string, destinationId: int, duration: string, essential: string, exclusions: list<string>, highlights: int, hotelPickup: bool, inclusions: list<string>, itinerary: string, location: string, mapURL: string, maxTravellerCount: int, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, merchantTermsAndConditions: record<amountRefundable: int, cancellationFromTourDate: list, merchantTermsAndConditionsType: int, termsAndConditions: string>, onRequestPeriod: int, onSale: bool, operates: string, panoramaCount: int, pas: record, passengerAttributes: list<record>, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: string, productPhotos: list<record>, productUrlName: string, rating: float, ratingCounts: record<"1": float, "2": float, "3": float, "4": float, "5": float>, region: string, returnDetails: string, reviewCount: int, reviews: list<record>, rrp: int, rrpFormatted: string, salesPoints: list<string>, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, specialOffer: string, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: bool, subCatIds: list<int>, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, tourGrades: list<record>, tourGradesAvailable: bool, translationLevel: int, userPhotos: list<record>, videoCount: int, videos: string, voucherOption: string, voucherRequirements: any, webURL: string>>
# operationId: product
export def "product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # **currency code** for the currency in which pricing is displayed - default=`'USD'`
  --sort-order: string@sort-order-completer # **specifier** of the order in which to return reviews Sort order options: - `"REVIEW_RATING_A"`: Traveler Rating (low→high) Average - `"REVIEW_RATING_D"`: Traveler Rating (high→low) Average - `"REVIEW_RATING_SUBMISSION_DATE_D"`: Most recent review
  --voucher-option: string@voucher-option-completer # - `"VOUCHER_PAPER_ONLY"`: Paper Vouchers only accepted - `"VOUCHER_E"`: EVouchers + Paper Vouchers accepted
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --exclude-tour-grade-availability: oneof<nothing, bool> # **specifier:** - `true`: return **all** tour grades, including those that are not available - `false`: only display tour grades that *are* available
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product"
    query: [{name: currencyCode, var: currency_code}, {name: sortOrder, var: sort_order}, {name: voucherOption, var: voucher_option}, {name: code, var: code}, {name: showUnavailable, var: show_unavailable}, {name: excludeTourGradeAvailability, var: exclude_tour_grade_availability}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    currency_code: $currency_code, sort_order: $sort_order, voucher_option: $voucher_option, code: $code, show_unavailable: $show_unavailable, exclude_tour_grade_availability: $exclude_tour_grade_availability, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /product/photos
#
# GET /product/photos
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<caption: string, editorsPick: bool, ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, photoHiResURL: string, photoId: int, photoMediumResURL: string, photoURL: string, productCode: string, productTitle: string, productUrlName: string, sortOrder: int, sslSupported: bool, thumbnailURL: string, timeUploaded: string, title: string>>
# operationId: productPhotos
export def "product-photos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'` (e.g. 1-3)
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product/photos"
    query: [{name: topX, var: top_x}, {name: code, var: code}, {name: showUnavailable, var: show_unavailable}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    top_x: $top_x, code: $code, show_unavailable: $show_unavailable, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /product/reviews
#
# GET /product/reviews
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<ownerAvatarURL: string, ownerCountry: string, ownerId: int, ownerName: string, productCode: string, productTitle: string, productUrlName: string, publishedDate: string, rating: int, review: string, reviewId: int, sortOrder: int, sslSupported: bool, submissionDate: string, viatorFeedback: string, viatorNotes: string>>
# operationId: productReviews
export def "product-reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-order: string@sort-order-completer # **specifier** of the order in which to return reviews Sort order options: - `"REVIEW_RATING_A"`: Traveler Rating (low→high) Average - `"REVIEW_RATING_D"`: Traveler Rating (high→low) Average - `"REVIEW_RATING_SUBMISSION_DATE_D"`: Most recent review
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'` (e.g. 1-3)
  --code: string # **unique alphanumeric identifier** of the product (e.g. 5010SYDNEY)
  --show-unavailable: oneof<nothing, bool> # **specifier** as to whether or not to show 'unavailable' products: - `true`: return *both* available and unavailable products - `false`: return *only* available products (default) (e.g. false)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/product/reviews"
    query: [{name: sortOrder, var: sort_order}, {name: topX, var: top_x}, {name: code, var: code}, {name: showUnavailable, var: show_unavailable}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    sort_order: $sort_order, top_x: $top_x, code: $code, show_unavailable: $show_unavailable, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /search/freetext
#
# POST /search/freetext
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<searchType: string, sortOrder: int>>
# operationId: searchFreetext
export def "search-freetext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display product pricing information
  --dest-id: int # **unique numeric identifier** of the destination to search within - `destinationId` can be retrieved from the [/taxonomy/destinations](#operation/taxonomyDestinations) service
  --search-types: list<string> # **array** of search domain specifiers where each item is *one of*: - `"PRODUCT"`: a tour / activity - `"DESTINATION"`: continent, country, city, region - `"ATTRACTION"`: an attraction within a destination (only available to partners with SEO access) - `"RECOMMENDATION"`: an attraction within a destination (only available to partners with SEO access)
  --sort-order: string@sort-order-completer-1 # **sort order** in which to return the results that is *one of*: - `'TOP_SELLERS'`: the top sellers - `'REVIEW_AVG_RATING_A'`: ascending by average traveler rating (low -> high) - `'REVIEW_AVG_RATING_D'`: descending by average traveler rating (high -> low) - `'PRICE_FROM_A'`: ascending by price (low -> high) - `'PRICE_FROM_D'`: descending by price (high -> low)
  --text: string # **text** to search for
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/freetext"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: currencyCode, var: currency_code}, {name: destId, var: dest_id}, {name: searchTypes, var: search_types}, {name: sortOrder, var: sort_order}, {name: text, var: text}, {name: topX, var: top_x}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, currency_code: $currency_code, dest_id: $dest_id, search_types: $search_types, sort_order: $sort_order, text: $text, top_x: $top_x
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /search/products
#
# POST /search/products
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, available: bool, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, primaryGroupId: int, productUrlName: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, sslSupported: any, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>
# operationId: searchProducts
export def "search-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --cat-id: int # **unique numeric identifier** of *this* product category to search within - `categoryId` can be retrieved from the [/taxonomy/categories](#operation/taxonomyCategories) service - at present, it is not possible to use `catId` in conjunction with `seoId`
  --currency-code: string # **currency** in which to display product prices
  --dest-id: int # **unique numeric identifier** of the destination in which to search for products - `destinationId` is available from the [/taxonomy/destinations](#operation/taxonomyDestinations) service - use **EITHER** `destId` **OR** `seoId`, but not both
  --end-date: string # **end date delimiter** for the search (must be in the future) - e.g., `'2019-10-21'`
  --seo-id: string # **search restriction specifier** for products associated with an attraction uniquely identified by `seoId` - use **EITHER** `destId` **OR** `seoId`, but not both
  --sort-order: string@sort-order-completer-1 # **sort order** in which to return the results that is *one of*: - `"TOP_SELLERS"`: the top sellers - `"REVIEW_AVG_RATING_A"`: ascending by average traveler rating (low -> high) - `"REVIEW_AVG_RATING_D"`: descending by average traveler rating (high -> low) - `"PRICE_FROM_A"`: ascending by price (low -> high) - `"PRICE_FROM_D"`: descending by price (high -> low)
  --start-date: string # **start date delimiter** for the search (must be in the future) - e.g., `'2018-10-21'`
  --sub-cat-id: int # **unique numeric identifier** of *this* product subcategory to search within - `subcategoryId` can be retrieved from the [/taxonomy/categories](#operation/taxonomyCategories) service - at present, it is not possible to use `subCatId` in conjunction with `seoId`
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/products"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: catId, var: cat_id}, {name: currencyCode, var: currency_code}, {name: destId, var: dest_id}, {name: endDate, var: end_date}, {name: seoId, var: seo_id}, {name: sortOrder, var: sort_order}, {name: startDate, var: start_date}, {name: subCatId, var: sub_cat_id}, {name: topX, var: top_x}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, cat_id: $cat_id, currency_code: $currency_code, dest_id: $dest_id, end_date: $end_date, seo_id: $seo_id, sort_order: $sort_order, start_date: $start_date, sub_cat_id: $sub_cat_id, top_x: $top_x
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /search/products/codes
#
# POST /search/products/codes
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<admission: string, bookingEngineId: string, catIds: list, code: string, currencyCode: string, duration: string, essential: string, merchantCancellable: bool, merchantNetPriceFrom: float, merchantNetPriceFromFormatted: string, onRequestPeriod: int, onSale: bool, panoramaCount: int, pas: record, photoCount: int, price: float, priceFormatted: string, primaryDestinationId: int, primaryDestinationName: string, primaryGroupId: string, rating: float, reviewCount: int, rrp: int, rrpformatted: string, savingAmount: string, savingAmountFormated: string, shortDescription: string, shortTitle: string, sortOrder: int, specialOfferAvailable: bool, specialReservation: bool, specialReservationDetails: string, subCatIds: list, supplierCode: string, supplierName: string, thumbnailHiResURL: string, thumbnailURL: string, title: string, translationLevel: int, uniqueShortDescription: string, videoCount: int, webURL: string>>
# operationId: searchProductsCodes
export def "search-products-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --currency-code: string # **currency code** for the currency in which to display product pricing
  --product-codes: list<string> # **array** of product codes to search for
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/products/codes"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: currencyCode, var: currency_code}, {name: productCodes, var: product_codes}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, currency_code: $currency_code, product_codes: $product_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /taxonomy/attractions
#
# POST /taxonomy/attractions
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<attractionCity: string, attractionLatitude: float, attractionLongitude: float, attractionState: string, attractionStreetAddress: string, destinationId: int, pageUrlName: string, photoCount: int, primaryDestinationId: int, primaryDestinationName: string, primaryDestinationUrlName: string, productCount: int, publishedDate: string, rating: float, seoId: int, sortOrder: int, thumbnailHiResURL: string, thumbnailURL: string, title: string, webURL: string>>
# operationId: taxonomyAttractions
export def "taxonomy-attractions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
  --dest-id: int # **unique numeric identifier** of the destination in which to search for attractions
  --sort-order: string@sort-order-completer-2 # **sort order** in which to return the results that is *one of*: * `"SEO_PUBLISHED_DATE_D"`: publish date (descending) * `"SEO_PUBLISHED_DATE_A"`: publish date (ascending) * `"SEO_REVIEW_AVG_RATING_D"`: traveler rating (high→low) * `"SEO_REVIEW_AVG_RATING_A"`: traveler rating (low→high) * `"SEO_ALPHABETICAL"`: alphabetical (A→Z)
  --top-x: string # **start and end rows** to return in the format {start}-{end} - e.g. `'1-10'`, `'11-20'` **Note**: - the maximum number of rows per request is 100; therefore, `'100-400'` will return the same as `'100-200'` - if `topX` is not specified, the default is `'1-100'`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/taxonomy/attractions"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: destId, var: dest_id}, {name: sortOrder, var: sort_order}, {name: topX, var: top_x}]}
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language, dest_id: $dest_id, sort_order: $sort_order, top_x: $top_x
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /taxonomy/categories
#
# GET /taxonomy/categories
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<groupName: string, groupUrlName: string, id: int, productCount: int, subcategories: list, thumbnailURL: string>>
# operationId: taxonomyCategories
export def "taxonomy-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dest-id: int # **unique numeric identifier** of the destination to enquire about (optional) - `destinationId` is returned by [/taxonomy/destinations](#operation/taxonomyDestinations) (e.g. 684)
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/taxonomy/categories"
    query: [{name: destId, var: dest_id}]
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    dest_id: $dest_id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# /taxonomy/destinations
#
# GET /taxonomy/destinations
# Returns: record<dateStamp: string, errorCodes: list<string>, errorMessage: list<any>, errorMessageText: string, errorName: string, errorReference: string, errorType: string, extraInfo: record, extraObject: record, success: bool, totalCount: int, vmid: string, data: table<defaultCurrencyCode: string, destinationId: int, destinationName: string, destinationType: string, destinationUrlName: string, iataCode: string, latitude: float, longitude: float, lookupId: string, parentId: int, selectable: bool, sortOrder: int, timeZone: string>>
# operationId: taxonomyDestinations
export def "taxonomy-destinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Specifies the language into which the natural-language fields in the response from this service will be translated (see [Accept-Language header](#section/Appendices/Accept-Language-header) for available langage codes) (required, e.g. en-US)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/taxonomy/destinations"
    header: [{name: Accept-Language, var: accept_language, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: exp-api-key
  } {
    accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
