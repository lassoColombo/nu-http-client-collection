# Auto-generated client for Legal Entity Management API v3
# Source: https://api.apis.guru/v2/specs/adyen.com/LegalEntityService/3/openapi.json
# Auth: --token flag or $env.LEGAL_ENTITY_MANAGEMENT_API_TOKEN

const CLIENT = {
  base_url: "https://kyc-test.adyen.com/lem/v3"
  token_env_var: "LEGAL_ENTITY_MANAGEMENT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://kyc-test.adyen.com/lem/v3"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def service-completer [] { ["banking" "issuing" "paymentProcessing"] }
def type-completer [] { ["bankStatement" "constitutionalDocument" "driversLicense" "identityCard" "nationalIdNumber" "passport" "proofOfAddress" "proofOfIndustry" "proofOfNationalIdNumber" "proofOfOrganizationTaxInfo" "proofOfResidency" "registrationDocument" "vatDocument"] }
def type-completer-1 [] { ["individual" "organization" "soleProprietorship" "trust" "unincorporatedPartnership"] }
def type-completer-2 [] { ["adyenAccount" "adyenCapital" "adyenCard" "adyenForPlatformsAdvanced" "adyenForPlatformsManage" "adyenFranchisee" "adyenIssuing"] }
def type-completer-3 [] { ["bankAccount" "recurringDetail"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-business-lines: "record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>"
    get-business-lines-id: "record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>"
    patch-business-lines-id: "record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>"
    post-documents: "record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>"
    delete-documents-id: "record"
    get-documents-id: "record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>"
    patch-documents-id: "record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>"
    post-legal-entities: "record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>"
    get-legal-entities-id: "record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>"
    patch-legal-entities-id: "record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>"
    get-legal-entities-id-business-lines: "record<businessLines: table<capability: string, id: string, industryCode: string, legalEntityId: string, problems: list, salesChannels: list, service: string, sourceOfFunds: record, webData: list, webDataExemption: record>>"
    post-legal-entities-id-check-verification-errors: "record<problems: table<entity: record, verificationErrors: list>>"
    post-legal-entities-id-onboarding-links: "record<url: string>"
    get-legal-entities-id-pci-questionnaires: "record<data: table<createdAt: string, id: string, validUntil: string>>"
    post-legal-entities-id-pci-questionnaires-generate-pci-templates: "record<content: string, language: string, pciTemplateReferences: list<string>>"
    post-legal-entities-id-pci-questionnaires-sign-pci-templates: "record<pciQuestionnaireIds: list<string>, signedBy: string>"
    get-legal-entities-id-pci-questionnaires-pciid: "record<content: string, createdAt: string, id: string, validUntil: string>"
    post-legal-entities-id-terms-of-service: "record<document: string, id: string, language: string, termsOfServiceDocumentId: string, type: string>"
    patch-legal-entities-id-terms-of-service-termsofservicedocumentid: "record<acceptedBy: string, id: string, ipAddress: string, language: string, termsOfServiceDocumentId: string, type: string>"
    get-legal-entities-id-terms-of-service-acceptance-infos: "record<data: table<acceptedBy: string, acceptedFor: string, createdAt: string, id: string, type: string>>"
    get-themes: "record<next: string, previous: string, themes: table<createdAt: string, description: string, id: string, properties: record, updatedAt: string>>"
    get-themes-id: "record<createdAt: string, description: string, id: string, properties: record, updatedAt: string>"
    post-transfer-instruments: "record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>"
    get-transfer-instruments-id: "record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>"
    patch-transfer-instruments-id: "record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-business-lines" "delete-business-lines-id" "get-business-lines-id" "patch-business-lines-id" "post-documents" "delete-documents-id" "get-documents-id" "patch-documents-id" "post-legal-entities" "get-legal-entities-id" "patch-legal-entities-id" "get-legal-entities-id-business-lines" "post-legal-entities-id-check-verification-errors" "post-legal-entities-id-onboarding-links" "get-legal-entities-id-pci-questionnaires" "post-legal-entities-id-pci-questionnaires-generate-pci-templates" "post-legal-entities-id-pci-questionnaires-sign-pci-templates" "get-legal-entities-id-pci-questionnaires-pciid" "post-legal-entities-id-terms-of-service" "patch-legal-entities-id-terms-of-service-termsofservicedocumentid" "get-legal-entities-id-terms-of-service-acceptance-infos" "get-themes" "get-themes-id" "post-transfer-instruments" "delete-transfer-instruments-id" "get-transfer-instruments-id" "patch-transfer-instruments-id" "commands"] | sort) } | get name | first)
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

# Create a business line
#
# POST /businessLines
# Returns: record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>
# operationId: post-businessLines
@deprecated --flag capability
export def "post-business-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  industry_code: string # A code that represents the industry of the legal entity. For example, **4431A** for computer software stores.
  legal_entity_id: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --sales-channels: list<string> # A list of channels where goods or services are sold. Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**. Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line. Possible values:**paymentProcessing**, **issuing**, **banking**
  --source-of-funds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --web-data: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --web-data-exemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/businessLines"
    body: {content_type: "application/json", kind: json, fields: [{name: capability, var: capability}, {name: industryCode, var: industry_code}, {name: legalEntityId, var: legal_entity_id}, {name: salesChannels, var: sales_channels}, {name: service, var: service}, {name: sourceOfFunds, var: source_of_funds}, {name: webData, var: web_data}, {name: webDataExemption, var: web_data_exemption}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    capability: $capability, industry_code: $industry_code, legal_entity_id: $legal_entity_id, sales_channels: $sales_channels, service: $service, source_of_funds: $source_of_funds, web_data: $web_data, web_data_exemption: $web_data_exemption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a business line
#
# DELETE /businessLines/{id}
# operationId: delete-businessLines-id
export def "delete-business-lines-id" [
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
    path: "/businessLines/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a business line
#
# GET /businessLines/{id}
# Returns: record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>
# operationId: get-businessLines-id
export def "get-business-lines-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/businessLines/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a business line
#
# PATCH /businessLines/{id}
# Returns: record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>>
# operationId: patch-businessLines-id
@deprecated --flag capability
export def "patch-business-lines-id" [
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
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  --industry-code: string # A code that represents the industry of your legal entity. For example, **4431A** for computer software stores.
  --legal-entity-id: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --sales-channels: list<string> # A list of channels where goods or services are sold. Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**. Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line. Possible values:**paymentProcessing**, **issuing**, **banking**
  --source-of-funds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --web-data: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --web-data-exemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/businessLines/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: capability, var: capability}, {name: industryCode, var: industry_code}, {name: legalEntityId, var: legal_entity_id}, {name: salesChannels, var: sales_channels}, {name: service, var: service}, {name: sourceOfFunds, var: source_of_funds}, {name: webData, var: web_data}, {name: webDataExemption, var: web_data_exemption}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, capability: $capability, industry_code: $industry_code, legal_entity_id: $legal_entity_id, sales_channels: $sales_channels, service: $service, source_of_funds: $source_of_funds, web_data: $web_data, web_data_exemption: $web_data_exemption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a document for verification checks
#
# POST /documents
# Returns: record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>
# operationId: post-documents
@deprecated --flag expiry-date
@deprecated --flag issuer-country
@deprecated --flag issuer-state
export def "post-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiry-date: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --file-name: string # The filename of the document.
  --issuer-country: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuer-state: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type. When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**. When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**. When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**. * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**. * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**. * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents"
    body: {content_type: "application/json", kind: json, fields: [{name: attachment, var: attachment}, {name: attachments, var: attachments}, {name: description, var: description}, {name: expiryDate, var: expiry_date}, {name: fileName, var: file_name}, {name: issuerCountry, var: issuer_country}, {name: issuerState, var: issuer_state}, {name: number, var: number}, {name: owner, var: owner}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    attachment: $attachment, attachments: $attachments, description: $description, expiry_date: $expiry_date, file_name: $file_name, issuer_country: $issuer_country, issuer_state: $issuer_state, number: $number, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a document
#
# DELETE /documents/{id}
# Returns: record
# operationId: delete-documents-id
export def "delete-documents-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a document
#
# GET /documents/{id}
# Returns: record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>
# operationId: get-documents-id
export def "get-documents-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a document
#
# PATCH /documents/{id}
# Returns: record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string>
# operationId: patch-documents-id
@deprecated --flag expiry-date
@deprecated --flag issuer-country
@deprecated --flag issuer-state
export def "patch-documents-id" [
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
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiry-date: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --file-name: string # The filename of the document.
  --issuer-country: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuer-state: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type. When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**. When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**. When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**. * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**. * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**. * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/documents/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachment, var: attachment}, {name: attachments, var: attachments}, {name: description, var: description}, {name: expiryDate, var: expiry_date}, {name: fileName, var: file_name}, {name: issuerCountry, var: issuer_country}, {name: issuerState, var: issuer_state}, {name: number, var: number}, {name: owner, var: owner}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, attachment: $attachment, attachments: $attachments, description: $description, expiry_date: $expiry_date, file_name: $file_name, issuer_country: $issuer_country, issuer_state: $issuer_state, number: $number, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a legal entity
#
# POST /legalEntities
# Returns: record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>
# operationId: post-legalEntities
export def "post-legal-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-associations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --sole-proprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  type: string@type-completer-1 # The type of legal entity. Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legalEntities"
    body: {content_type: "application/json", kind: json, fields: [{name: entityAssociations, var: entity_associations}, {name: individual, var: individual}, {name: organization, var: organization}, {name: reference, var: reference}, {name: soleProprietorship, var: sole_proprietorship}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    entity_associations: $entity_associations, individual: $individual, organization: $organization, reference: $reference, sole_proprietorship: $sole_proprietorship, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a legal entity
#
# GET /legalEntities/{id}
# Returns: record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>
# operationId: get-legalEntities-id
export def "get-legal-entities-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legalEntities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a legal entity
#
# PATCH /legalEntities/{id}
# Returns: record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string>
# operationId: patch-legalEntities-id
export def "patch-legal-entities-id" [
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
  --entity-associations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --sole-proprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  --type: string@type-completer-1 # The type of legal entity. Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/legalEntities/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityAssociations, var: entity_associations}, {name: individual, var: individual}, {name: organization, var: organization}, {name: reference, var: reference}, {name: soleProprietorship, var: sole_proprietorship}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, entity_associations: $entity_associations, individual: $individual, organization: $organization, reference: $reference, sole_proprietorship: $sole_proprietorship, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all business lines under a legal entity
#
# GET /legalEntities/{id}/businessLines
# Returns: record<businessLines: table<capability: string, id: string, industryCode: string, legalEntityId: string, problems: list, salesChannels: list, service: string, sourceOfFunds: record, webData: list, webDataExemption: record>>
# operationId: get-legalEntities-id-businessLines
export def "get-legal-entities-id-business-lines" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legalEntities/{id}/businessLines"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check a legal entity's verification errors
#
# POST /legalEntities/{id}/checkVerificationErrors
# Returns: record<problems: table<entity: record, verificationErrors: list>>
# operationId: post-legalEntities-id-checkVerificationErrors
export def "post-legal-entities-id-check-verification-errors" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/legalEntities/{id}/checkVerificationErrors"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a link to an Adyen-hosted onboarding page
#
# POST /legalEntities/{id}/onboardingLinks
# Returns: record<url: string>
# operationId: post-legalEntities-id-onboardingLinks
export def "post-legal-entities-id-onboarding-links" [
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
  --locale: string # The language that will be used for the page, specified by a combination of two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language and [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes. See [possible values](https://docs.adyen.com/marketplaces-and-platforms/collect-verification-details/hosted#supported-languages). If not specified in the request or if the language is not supported, the page uses the browser language. If the browser language is not supported, the page uses **en-US** by default.
  --redirect-url: string # The URL where the user is redirected after they complete hosted onboarding.
  --settings: record # Boolean key-value pairs indicating the settings for the hosted onboarding page. The keys are the settings. By default, the values are set to **true**. Set to **false** to not allow the action. Possible keys: - **changeLegalEntityType**: The user can change their legal entity type. - **editPrefilledCountry**: The user can change the country of their legal entity's address, for example the registered address of an organization.
  --theme-id: string # The unique identifier of the hosted onboarding theme.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legalEntities/{id}/onboardingLinks"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: locale, var: locale}, {name: redirectUrl, var: redirect_url}, {name: settings, var: settings}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, locale: $locale, redirect_url: $redirect_url, settings: $settings, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get PCI questionnaire details
#
# GET /legalEntities/{id}/pciQuestionnaires
# Returns: record<data: table<createdAt: string, id: string, validUntil: string>>
# operationId: get-legalEntities-id-pciQuestionnaires
export def "get-legal-entities-id-pci-questionnaires" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legalEntities/{id}/pciQuestionnaires"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/generatePciTemplates
# Returns: record<content: string, language: string, pciTemplateReferences: list<string>>
# operationId: post-legalEntities-id-pciQuestionnaires-generatePciTemplates
export def "post-legal-entities-id-pci-questionnaires-generate-pci-templates" [
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
  --language: string # Sets the language of the PCI questionnaire. Its value is a two-character [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1) language code, for example, **en**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legalEntities/{id}/pciQuestionnaires/generatePciTemplates"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: language, var: language}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sign PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/signPciTemplates
# Returns: record<pciQuestionnaireIds: list<string>, signedBy: string>
# operationId: post-legalEntities-id-pciQuestionnaires-signPciTemplates
export def "post-legal-entities-id-pci-questionnaires-sign-pci-templates" [
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
  pci_template_references: list<string> # The array of Adyen-generated unique identifiers for the questionnaires.
  signed_by: string # The [legal entity ID](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) of the individual who signs the PCI questionnaire.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legalEntities/{id}/pciQuestionnaires/signPciTemplates"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: pciTemplateReferences, var: pci_template_references}, {name: signedBy, var: signed_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, pci_template_references: $pci_template_references, signed_by: $signed_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get PCI questionnaire
#
# GET /legalEntities/{id}/pciQuestionnaires/{pciid}
# Returns: record<content: string, createdAt: string, id: string, validUntil: string>
# operationId: get-legalEntities-id-pciQuestionnaires-pciid
export def "get-legal-entities-id-pci-questionnaires-pciid" [
  id: string
  pciid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/legalEntities/{id}/pciQuestionnaires/{pciid}"
    path_params: [{name: id, var: id}, {name: pciid, var: pciid}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, pciid: $pciid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Terms of Service document
#
# POST /legalEntities/{id}/termsOfService
# Returns: record<document: string, id: string, language: string, termsOfServiceDocumentId: string, type: string>
# operationId: post-legalEntities-id-termsOfService
export def "post-legal-entities-id-terms-of-service" [
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
  --language: string # The language to be used for the Terms of Service document, specified by the two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code. For example, **nl** for Dutch.
  --type: string@type-completer-2 # The type of Terms of Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/legalEntities/{id}/termsOfService"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: language, var: language}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, language: $language, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept Terms of Service
#
# PATCH /legalEntities/{id}/termsOfService/{termsofservicedocumentid}
# Returns: record<acceptedBy: string, id: string, ipAddress: string, language: string, termsOfServiceDocumentId: string, type: string>
# operationId: patch-legalEntities-id-termsOfService-termsofservicedocumentid
export def "patch-legal-entities-id-terms-of-service-termsofservicedocumentid" [
  id: string
  termsofservicedocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-by: string # The unique identifier of the user accepting the Terms of Service.
  --ip-address: string # The IP address of the user accepting the Terms of Service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/legalEntities/{id}/termsOfService/{termsofservicedocumentid}"
    path_params: [{name: id, var: id}, {name: termsofservicedocumentid, var: termsofservicedocumentid}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptedBy, var: accepted_by}, {name: ipAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, termsofservicedocumentid: $termsofservicedocumentid, accepted_by: $accepted_by, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Terms of Service information for a legal entity
#
# GET /legalEntities/{id}/termsOfServiceAcceptanceInfos
# Returns: record<data: table<acceptedBy: string, acceptedFor: string, createdAt: string, id: string, type: string>>
# operationId: get-legalEntities-id-termsOfServiceAcceptanceInfos
export def "get-legal-entities-id-terms-of-service-acceptance-infos" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/legalEntities/{id}/termsOfServiceAcceptanceInfos"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of hosted onboarding page themes
#
# GET /themes
# Returns: record<next: string, previous: string, themes: table<createdAt: string, description: string, id: string, properties: record, updatedAt: string>>
# operationId: get-themes
export def "get-themes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/themes"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an onboarding link theme
#
# GET /themes/{id}
# Returns: record<createdAt: string, description: string, id: string, properties: record, updatedAt: string>
# operationId: get-themes-id
export def "get-themes-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/themes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transfer instrument
#
# POST /transferInstruments
# Returns: record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>
# operationId: post-transferInstruments
export def "post-transfer-instruments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_account: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument. Possible value: **bankAccount**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transferInstruments"
    body: {content_type: "application/json", kind: json, fields: [{name: bankAccount, var: bank_account}, {name: legalEntityId, var: legal_entity_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    bank_account: $bank_account, legal_entity_id: $legal_entity_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transfer instrument
#
# DELETE /transferInstruments/{id}
# operationId: delete-transferInstruments-id
export def "delete-transfer-instruments-id" [
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
    path: "/transferInstruments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a transfer instrument
#
# GET /transferInstruments/{id}
# Returns: record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>
# operationId: get-transferInstruments-id
export def "get-transfer-instruments-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transferInstruments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a transfer instrument
#
# PATCH /transferInstruments/{id}
# Returns: record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string>
# operationId: patch-transferInstruments-id
export def "patch-transfer-instruments-id" [
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
  bank_account: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument. Possible value: **bankAccount**.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transferInstruments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bankAccount, var: bank_account}, {name: legalEntityId, var: legal_entity_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, bank_account: $bank_account, legal_entity_id: $legal_entity_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
