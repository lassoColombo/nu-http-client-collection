# Auto-generated client for Azure Alerts Management Service Resource Provider v2019-05-05-preview
# Source: https://api.apis.guru/v2/specs/azure.com/alertsmanagement-AlertsManagement/2019-05-05-preview/swagger.json
# Auth: --token flag or $env.AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["2019-05-05-preview"] }
def identifier-completer [] { ["MonitorServiceList"] }
def severity-completer [] { ["Sev0" "Sev1" "Sev2" "Sev3" "Sev4"] }
def monitor-service-completer [] { ["ActivityLog Administrative" "ActivityLog Autoscale" "ActivityLog Policy" "ActivityLog Recommendation" "ActivityLog Security" "Application Insights" "Log Analytics" "Nagios" "Platform" "SCOM" "ServiceHealth" "SmartDetector" "VM Insights" "Zabbix"] }
def monitor-condition-completer [] { ["Fired" "Resolved"] }
def alert-state-completer [] { ["Acknowledged" "Closed" "New"] }
def sort-by-completer [] { ["alertState" "lastModifiedDateTime" "monitorCondition" "name" "severity" "startDateTime" "targetResource" "targetResourceGroup" "targetResourceName" "targetResourceType"] }
def sort-order-completer [] { ["asc" "desc"] }
def time-range-completer [] { ["1d" "1h" "30d" "7d"] }
def new-state-completer [] { ["Acknowledged" "Closed" "New"] }
def groupby-completer [] { ["alertRule" "alertState" "monitorCondition" "monitorService" "severity" "signalType"] }
def smart-group-state-completer [] { ["Acknowledged" "Closed" "New"] }
def sort-by-completer-1 [] { ["alertsCount" "lastModifiedDateTime" "severity" "startDateTime" "state"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    alerts-meta-data: "record<properties: record<metadataIdentifier: string>>"
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    action-rules-list-by-subscription: "record<nextLink: string, value: table<properties: record, location: string, tags: any, id: string, name: string, type: string>>"
    alerts-get-all: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    alerts-get-by-id: "record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string>"
    alerts-change-state: "record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string>"
    alerts-get-history: "record<properties: record<alertId: string, modifications: list<record>>, id: string, name: string, type: string>"
    alerts-get-summary: "record<properties: record<groupedby: string, smartGroupsCount: int, total: int, values: list<record>>, id: string, name: string, type: string>"
    smart-groups-get-all: "record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>"
    smart-groups-get-by-id: "record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string>"
    smart-groups-change-state: "record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string>"
    smart-groups-get-history: "record<properties: record<modifications: list<record>, nextLink: string, smartGroupId: string>, id: string, name: string, type: string>"
    action-rules-list-by-resource-group: "record<nextLink: string, value: table<properties: record, location: string, tags: any, id: string, name: string, type: string>>"
    action-rules-delete: "bool"
    action-rules-get-by-name: "record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>"
    action-rules-update: "record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>"
    action-rules-create-update: "record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["alerts-meta-data" "operations-list" "action-rules-list-by-subscription" "alerts-get-all" "alerts-get-by-id" "alerts-change-state" "alerts-get-history" "alerts-get-summary" "smart-groups-get-all" "smart-groups-get-by-id" "smart-groups-change-state" "smart-groups-get-history" "action-rules-list-by-resource-group" "action-rules-delete" "action-rules-get-by-name" "action-rules-update" "action-rules-create-update" "commands"] | sort) } | get name | first)
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

# List alerts meta data information based on value of identifier parameter.
#
# GET /providers/Microsoft.AlertsManagement/alertsMetaData
# Returns: record<properties: record<metadataIdentifier: string>>
# operationId: Alerts_MetaData
export def "alerts-meta-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
  --identifier: string@identifier-completer # Identification of the information to be retrieved by API call. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.AlertsManagement/alertsMetaData"
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}, {name: identifier, var: identifier, required: true, default: MonitorServiceList}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all operations available through Azure Alerts Management Resource Provider.
#
# GET /providers/Microsoft.AlertsManagement/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.AlertsManagement/operations"
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all action rule in a given subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/actionRules
# Returns: record<nextLink: string, value: table<properties: record, location: string, tags: any, id: string, name: string, type: string>>
# operationId: ActionRules_ListBySubscription
export def "action-rules-list-by-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --impacted-scope: string # filter by impacted/target scope (provide comma separated list for multiple scopes). The value should be an well constructed ARM id of the scope.
  --description: string # filter by alert rule description
  --alert-rule-id: string # filter by alert rule id
  --action-group: string # filter by action group configured as part of action rule
  --name: string # filter by action rule name
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/actionRules"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: targetResourceGroup, var: target_resource_group}, {name: targetResourceType, var: target_resource_type}, {name: targetResource, var: target_resource}, {name: severity, var: severity}, {name: monitorService, var: monitor_service}, {name: impactedScope, var: impacted_scope}, {name: description, var: description}, {name: alertRuleId, var: alert_rule_id}, {name: actionGroup, var: action_group}, {name: name, var: name}, {name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, target_resource_group: $target_resource_group, target_resource_type: $target_resource_type, target_resource: $target_resource, severity: $severity, monitor_service: $monitor_service, impacted_scope: $impacted_scope, description: $description, alert_rule_id: $alert_rule_id, action_group: $action_group, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all existing alerts, where the results can be filtered on the basis of multiple parameters (e.g. time range). The results can then be sorted on the basis specific fields, with the default being lastModifiedDateTime.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: Alerts_GetAll
export def "alerts-get-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --alert-state: string@alert-state-completer # Filter by state of the alert instance. Default value is to select all.
  --alert-rule: string # Filter by specific alert rule. Default value is to select all.
  --smart-group-id: string # Filter the alerts list by the Smart Group Id. Default value is none.
  --include-context: oneof<nothing, bool> # Include context which has contextual data specific to the monitor service. Default value is false'
  --include-egress-config: oneof<nothing, bool> # Include egress config which would be used for displaying the content in portal. Default value is 'false'.
  --page-count: int # Determines number of alerts returned per page in response. Permissible value is between 1 to 250. When the "includeContent" filter is selected, maximum value allowed is 25. Default value is 25.
  --sort-by: string@sort-by-completer # Sort the query results by input field, Default value is 'lastModifiedDateTime'.
  --sort-order: string@sort-order-completer # Sort the query results order in either ascending or descending. Default value is 'desc' for time fields and 'asc' for others.
  --select: string # This filter allows to selection of the fields(comma separated) which would be part of the essential section. This would allow to project only the required fields rather than getting entire content. Default is to fetch all the fields in the essentials section.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --custom-time-range: string # Filter by custom time range in the format <start-time>/<end-time> where time is in (ISO-8601 format)'. Permissible values is within 30 days from query time. Either timeRange or customTimeRange could be used but not both. Default is none.
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: targetResource, var: target_resource}, {name: targetResourceType, var: target_resource_type}, {name: targetResourceGroup, var: target_resource_group}, {name: monitorService, var: monitor_service}, {name: monitorCondition, var: monitor_condition}, {name: severity, var: severity}, {name: alertState, var: alert_state}, {name: alertRule, var: alert_rule}, {name: smartGroupId, var: smart_group_id}, {name: includeContext, var: include_context}, {name: includeEgressConfig, var: include_egress_config}, {name: pageCount, var: page_count}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: select, var: select}, {name: timeRange, var: time_range}, {name: customTimeRange, var: custom_time_range}, {name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, target_resource: $target_resource, target_resource_type: $target_resource_type, target_resource_group: $target_resource_group, monitor_service: $monitor_service, monitor_condition: $monitor_condition, severity: $severity, alert_state: $alert_state, alert_rule: $alert_rule, smart_group_id: $smart_group_id, include_context: $include_context, include_egress_config: $include_egress_config, page_count: $page_count, sort_by: $sort_by, sort_order: $sort_order, select: $select, time_range: $time_range, custom_time_range: $custom_time_range, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific alert.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}
# Returns: record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string>
# operationId: Alerts_GetById
export def "alerts-get-by-id" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: alertId, var: alert_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, alert_id: $alert_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the state of an alert.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/changestate
# Returns: record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string>
# operationId: Alerts_ChangeState
export def "alerts-change-state" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
  --new-state: string@new-state-completer # New state of the alert. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/changestate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: alertId, var: alert_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}, {name: newState, var: new_state, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, alert_id: $alert_id, api_version: $api_version, new_state: $new_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the history of an alert, which captures any monitor condition changes (Fired/Resolved) and alert state changes (New/Acknowledged/Closed).
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/history
# Returns: record<properties: record<alertId: string, modifications: list<record>>, id: string, name: string, type: string>
# operationId: Alerts_GetHistory
export def "alerts-get-history" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/history"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: alertId, var: alert_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, alert_id: $alert_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summarized count of your alerts grouped by various parameters (e.g. grouping by 'Severity' returns the count of alerts for each severity).
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alertsSummary
# Returns: record<properties: record<groupedby: string, smartGroupsCount: int, total: int, values: list<record>>, id: string, name: string, type: string>
# operationId: Alerts_GetSummary
export def "alerts-get-summary" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupby: string@groupby-completer # This parameter allows the result set to be grouped by input fields (Maximum 2 comma separated fields supported). For example, groupby=severity or groupby=severity,alertstate. (required)
  --include-smart-groups-count: oneof<nothing, bool> # Include count of the SmartGroups as part of the summary. Default value is 'false'.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --alert-state: string@alert-state-completer # Filter by state of the alert instance. Default value is to select all.
  --alert-rule: string # Filter by specific alert rule. Default value is to select all.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --custom-time-range: string # Filter by custom time range in the format <start-time>/<end-time> where time is in (ISO-8601 format)'. Permissible values is within 30 days from query time. Either timeRange or customTimeRange could be used but not both. Default is none.
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alertsSummary"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: groupby, var: groupby, required: true}, {name: includeSmartGroupsCount, var: include_smart_groups_count}, {name: targetResource, var: target_resource}, {name: targetResourceType, var: target_resource_type}, {name: targetResourceGroup, var: target_resource_group}, {name: monitorService, var: monitor_service}, {name: monitorCondition, var: monitor_condition}, {name: severity, var: severity}, {name: alertState, var: alert_state}, {name: alertRule, var: alert_rule}, {name: timeRange, var: time_range}, {name: customTimeRange, var: custom_time_range}, {name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, groupby: $groupby, include_smart_groups_count: $include_smart_groups_count, target_resource: $target_resource, target_resource_type: $target_resource_type, target_resource_group: $target_resource_group, monitor_service: $monitor_service, monitor_condition: $monitor_condition, severity: $severity, alert_state: $alert_state, alert_rule: $alert_rule, time_range: $time_range, custom_time_range: $custom_time_range, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Smart Groups within a specified subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups
# Returns: record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>>
# operationId: SmartGroups_GetAll
export def "smart-groups-get-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --smart-group-state: string@smart-group-state-completer # Filter by state of the smart group. Default value is to select all.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --page-count: int # Determines number of alerts returned per page in response. Permissible value is between 1 to 250. When the "includeContent" filter is selected, maximum value allowed is 25. Default value is 25.
  --sort-by: string@sort-by-completer-1 # Sort the query results by input field. Default value is sort by 'lastModifiedDateTime'.
  --sort-order: string@sort-order-completer # Sort the query results order in either ascending or descending. Default value is 'desc' for time fields and 'asc' for others.
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: targetResource, var: target_resource}, {name: targetResourceGroup, var: target_resource_group}, {name: targetResourceType, var: target_resource_type}, {name: monitorService, var: monitor_service}, {name: monitorCondition, var: monitor_condition}, {name: severity, var: severity}, {name: smartGroupState, var: smart_group_state}, {name: timeRange, var: time_range}, {name: pageCount, var: page_count}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, target_resource: $target_resource, target_resource_group: $target_resource_group, target_resource_type: $target_resource_type, monitor_service: $monitor_service, monitor_condition: $monitor_condition, severity: $severity, smart_group_state: $smart_group_state, time_range: $time_range, page_count: $page_count, sort_by: $sort_by, sort_order: $sort_order, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information related to a specific Smart Group.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}
# Returns: record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string>
# operationId: SmartGroups_GetById
export def "smart-groups-get-by-id" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: smartGroupId, var: smart_group_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, smart_group_id: $smart_group_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the state of a Smart Group.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/changeState
# Returns: record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string>
# operationId: SmartGroups_ChangeState
export def "smart-groups-change-state" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
  --new-state: string@new-state-completer # New state of the alert. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/changeState"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: smartGroupId, var: smart_group_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}, {name: newState, var: new_state, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, smart_group_id: $smart_group_id, api_version: $api_version, new_state: $new_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the history a smart group, which captures any Smart Group state changes (New/Acknowledged/Closed) .
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/history
# Returns: record<properties: record<modifications: list<record>, nextLink: string, smartGroupId: string>, id: string, name: string, type: string>
# operationId: SmartGroups_GetHistory
export def "smart-groups-get-history" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/history"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: smartGroupId, var: smart_group_id}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, smart_group_id: $smart_group_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all action rules created in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules
# Returns: record<nextLink: string, value: table<properties: record, location: string, tags: any, id: string, name: string, type: string>>
# operationId: ActionRules_ListByResourceGroup
export def "action-rules-list-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --impacted-scope: string # filter by impacted/target scope (provide comma separated list for multiple scopes). The value should be an well constructed ARM id of the scope.
  --description: string # filter by alert rule description
  --alert-rule-id: string # filter by alert rule id
  --action-group: string # filter by action group configured as part of action rule
  --name: string # filter by action rule name
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: targetResourceGroup, var: target_resource_group}, {name: targetResourceType, var: target_resource_type}, {name: targetResource, var: target_resource}, {name: severity, var: severity}, {name: monitorService, var: monitor_service}, {name: impactedScope, var: impacted_scope}, {name: description, var: description}, {name: alertRuleId, var: alert_rule_id}, {name: actionGroup, var: action_group}, {name: name, var: name}, {name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, target_resource_group: $target_resource_group, target_resource_type: $target_resource_type, target_resource: $target_resource, severity: $severity, monitor_service: $monitor_service, impacted_scope: $impacted_scope, description: $description, alert_rule_id: $alert_rule_id, action_group: $action_group, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete action rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# Returns: bool
# operationId: ActionRules_Delete
export def "action-rules-delete" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: actionRuleName, var: action_rule_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, action_rule_name: $action_rule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get action rule by name
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# Returns: record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>
# operationId: ActionRules_GetByName
export def "action-rules-get-by-name" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: actionRuleName, var: action_rule_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, action_rule_name: $action_rule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch action rule
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# Returns: record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>
# operationId: ActionRules_Update
export def "action-rules-update" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
  --properties: any # Action rule properties supported by patch — shape: {status?: "Enabled"|"Disabled"}
  --tags: record # tags to be updated
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: actionRuleName, var: action_rule_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, action_rule_name: $action_rule_name, api_version: $api_version, properties: $properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create/update an action rule
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# Returns: record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any, id: string, name: string, type: string>
# operationId: ActionRules_CreateUpdate
export def "action-rules-create-update" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version (required)
  --properties: any # Action rule properties defining scope, conditions, suppression logic for action rule — shape: {conditions?: record, description?: string, scope?: record, status?: "Enabled"|"Disabled", type: "Suppression"|"ActionGroup"|"Diagnostics"}
  location: string # Resource location
  --tags: any # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: actionRuleName, var: action_rule_name}]
    query: [{name: api-version, var: api_version, required: true, default: "2019-05-05-preview"}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, action_rule_name: $action_rule_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
