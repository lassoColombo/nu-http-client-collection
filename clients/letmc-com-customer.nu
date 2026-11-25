# Auto-generated client for agentOS Api V2, Customer Login Call Group v2-customer
# Source: https://api.apis.guru/v2/specs/letmc.com/customer/v2-customer/openapi.json
# Auth: --token flag or $env.AGENTOS_API_V2_CUSTOMER_LOGIN_CALL_GROUP_TOKEN

const CLIENT = {
  base_url: "https://live-api.letmc.com"
  token_env_var: "AGENTOS_API_V2_CUSTOMER_LOGIN_CALL_GROUP_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: apikey, in: header, header_name: ApiKey, prefix: ""}
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    branch-controller-get-branches: "record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>"
    get-v2-customer-short-name-branch-branches-branch-id: "record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>"
    landlord-controller-get-accounts: "record<AccountBalance: float, LastPayment: string, PaymentHistory: table<Amount: float, Date: string, Description: string, TransactionNumber: int>, Statements: table<Date: string, InvoiceID: string, IsMaintenanceInvoice: bool>>"
    landlord-controller-get-document: "record"
    landlord-controller-get-invetory-report: "record"
    landlord-controller-get-invoice: "record"
    landlord-controller-get-landlord-crm-entries: "table<BranchID: string, GlobalReference: string, Name: string, OID: string>"
    landlord-controller-get-maintenance-jobs: "record<Jobs: table<AssignedTo: string, ClosedDate: string, Description: string, MaintenanceNotes: list, Property: string, Reported: string, Status: string>>"
    landlord-controller-get-profit-loss-report: "record<DirectCosts: record<Rows: list<record>>, GrossProfitLoss: record<Rows: list<record>>, Income: record<Rows: list<record>>>"
    landlord-controller-get-rent-arrears: "record<ChaseNotes: table<Date: string, Note: string, NoteType: string, TenantID: string>, RentCollected: float, RentOutstanding: table<DebtDays: int, OutstandingRent: float, Property: string, Tenant: string, TenantID: string>, TotalRentArrears: float>"
    landlord-controller-get-sas-report: "record"
    landlord-controller-get-settings: "record<LinkedAccounts: table<Address: string, Email: string, GlobalReference: string, ID: string, Mobile: string, Name: string, Phone: string>>"
    landlord-controller-get-summary-details: "record<AccountBalance: float, LastPayment: string, Tenancies: table<Bond: float, BranchID: string, Description: string, GlobalReference: string, ID: string, MaintenanceJobs: int, ManagedRent: bool, PropertyAddress: string, Rent: string, RentArrears: float, RentCollected: float, TenancyProperty: string, TenancyState: string>, TotalRentArrears: float>"
    landlord-controller-get-tenancy: "record<ActualEndDate: string, Beds: int, Bond: float, BranchID: string, Certificates: table<Due: string, Files: list, Status: string, Type: string>, Documents: table<FileName: string, FileSize: int, ID: string, MIMEType: string, Note: string>, FixedDate: string, GlobalReference: string, ID: string, Inspections: table<InspectionDate: string, Notes: string>, ManagedRent: bool, Preferences: table<Name: string, Notes: string, Type: string>, PreviousRentAmount: float, PropertyAddress: string, Rent: string, RentAmount: float, StartDate: string, TenancyProperty: string, TenancyState: string, Tenants: list<string>>"
    landlord-controller-create-maintenance-preference: "string"
    landlord-controller-get-tenancy-agreement-report: "record"
    photo-controller-get-photo-download: "record"
    property-controller-get-properties-photos: "record<Count: int, Data: table<ETag: string, FileName: string, OID: string, PhotoType: string>>"
    session-controller-get-session-info: "string"
    session-controller-login: "string"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["branch-controller-get-branches" "get-v2-customer-short-name-branch-branches-branch-id" "landlord-controller-get-accounts" "landlord-controller-get-document" "landlord-controller-get-invetory-report" "landlord-controller-get-invoice" "landlord-controller-get-landlord-crm-entries" "landlord-controller-get-maintenance-jobs" "landlord-controller-get-profit-loss-report" "landlord-controller-get-rent-arrears" "landlord-controller-get-sas-report" "landlord-controller-get-settings" "landlord-controller-get-summary-details" "landlord-controller-get-tenancy" "landlord-controller-create-maintenance-preference" "landlord-controller-get-tenancy-agreement-report" "photo-controller-get-photo-download" "property-controller-get-properties-photos" "session-controller-logout" "session-controller-get-session-info" "session-controller-login" "session-controller-create-landlord-login" "session-controller-change-password" "session-controller-reset-password" "commands"] | sort) } | get name | first)
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

# All branches defined for a company
#
# GET /v2/customer/{shortName}/branch/branches
# Returns: record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>
# operationId: BranchController_GetBranches
export def "branch-controller-get-branches" [
  short_name: string
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/branch/branches"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v2/customer/{shortName}/branch/branches/{branchID}
# Returns: record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>
export def "get-v2-customer-short-name-branch-branches-branch-id" [
  short_name: string
  branch_id: string
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
    path: "/v2/customer/{shortName}/branch/branches/{branchID}"
    path_params: [{name: shortName, var: short_name}, {name: branchID, var: branch_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, branch_id: $branch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the accounting details for the landlord.
#
# GET /v2/customer/{shortName}/landlord/accounting
# Returns: record<AccountBalance: float, LastPayment: string, PaymentHistory: table<Amount: float, Date: string, Description: string, TransactionNumber: int>, Statements: table<Date: string, InvoiceID: string, IsMaintenanceInvoice: bool>>
# operationId: LandlordController_GetAccounts
export def "landlord-controller-get-accounts" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/accounting"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Download a Document
#
# GET /v2/customer/{shortName}/landlord/document
# Returns: record
# operationId: LandlordController_GetDocument
export def "landlord-controller-get-document" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --id: string # The Document ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/document"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: ID, var: id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a Inventory PDF for a tenancy
#
# GET /v2/customer/{shortName}/landlord/inventory
# Returns: record
# operationId: LandlordController_GetInvetoryReport
export def "landlord-controller-get-invetory-report" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --tenancy-id: string # The Tenancy ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/inventory"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: tenancyID, var: tenancy_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, tenancy_id: $tenancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an invoice pdf belonging to the landlord.
#
# GET /v2/customer/{shortName}/landlord/invoice
# Returns: record
# operationId: LandlordController_GetInvoice
export def "landlord-controller-get-invoice" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --invoice-id: string # The invoice ID to load. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/invoice"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: invoiceID, var: invoice_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve landlord's CRM ID
#
# GET /v2/customer/{shortName}/landlord/landlordcrmentries
# Returns: table<BranchID: string, GlobalReference: string, Name: string, OID: string>
# operationId: LandlordController_GetLandlordCrmEntries
export def "landlord-controller-get-landlord-crm-entries" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/landlordcrmentries"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Active maintenance jobs.
#
# GET /v2/customer/{shortName}/landlord/maintenance
# Returns: record<Jobs: table<AssignedTo: string, ClosedDate: string, Description: string, MaintenanceNotes: list, Property: string, Reported: string, Status: string>>
# operationId: LandlordController_GetMaintenanceJobs
export def "landlord-controller-get-maintenance-jobs" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/maintenance"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a Profit and Loss Report
#
# GET /v2/customer/{shortName}/landlord/profitloss
# Returns: record<DirectCosts: record<Rows: list<record>>, GrossProfitLoss: record<Rows: list<record>>, Income: record<Rows: list<record>>>
# operationId: LandlordController_GetProfitLossReport
export def "landlord-controller-get-profit-loss-report" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/profitloss"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Rent Arrears
#
# GET /v2/customer/{shortName}/landlord/rentarrears
# Returns: record<ChaseNotes: table<Date: string, Note: string, NoteType: string, TenantID: string>, RentCollected: float, RentOutstanding: table<DebtDays: int, OutstandingRent: float, Property: string, Tenant: string, TenantID: string>, TotalRentArrears: float>
# operationId: LandlordController_GetRentArrears
export def "landlord-controller-get-rent-arrears" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/rentarrears"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a Self Assessment Tax Report
#
# GET /v2/customer/{shortName}/landlord/sas
# Returns: record
# operationId: LandlordController_GetSASReport
export def "landlord-controller-get-sas-report" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --year-end: int # The Tax Year End. (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/sas"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: yearEnd, var: year_end, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, year_end: $year_end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get contact details of all linked landlords.
#
# GET /v2/customer/{shortName}/landlord/settings
# Returns: record<LinkedAccounts: table<Address: string, Email: string, GlobalReference: string, ID: string, Mobile: string, Name: string, Phone: string>>
# operationId: LandlordController_GetSettings
export def "landlord-controller-get-settings" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/settings"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the summary details for the landlord.
#
# GET /v2/customer/{shortName}/landlord/summary
# Returns: record<AccountBalance: float, LastPayment: string, Tenancies: table<Bond: float, BranchID: string, Description: string, GlobalReference: string, ID: string, MaintenanceJobs: int, ManagedRent: bool, PropertyAddress: string, Rent: string, RentArrears: float, RentCollected: float, TenancyProperty: string, TenancyState: string>, TotalRentArrears: float>
# operationId: LandlordController_GetSummaryDetails
export def "landlord-controller-get-summary-details" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/summary"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get tenancy details.
#
# GET /v2/customer/{shortName}/landlord/tenancy
# Returns: record<ActualEndDate: string, Beds: int, Bond: float, BranchID: string, Certificates: table<Due: string, Files: list, Status: string, Type: string>, Documents: table<FileName: string, FileSize: int, ID: string, MIMEType: string, Note: string>, FixedDate: string, GlobalReference: string, ID: string, Inspections: table<InspectionDate: string, Notes: string>, ManagedRent: bool, Preferences: table<Name: string, Notes: string, Type: string>, PreviousRentAmount: float, PropertyAddress: string, Rent: string, RentAmount: float, StartDate: string, TenancyProperty: string, TenancyState: string, Tenants: list<string>>
# operationId: LandlordController_GetTenancy
export def "landlord-controller-get-tenancy" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --tenancy-id: string # The Tenancy ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/tenancy"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: tenancyID, var: tenancy_id, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, tenancy_id: $tenancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Post tenancy maintenance preferences:-
#
# POST /v2/customer/{shortName}/landlord/tenancy/maintenance/preference
# Returns: string
# operationId: LandlordController_CreateMaintenancePreference
export def "landlord-controller-create-maintenance-preference" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --tenancy-id: string # The Tenancy ID (required)
  --name: string # Name of the maintenance preference to add (required)
  --notes: string # Notes of the maintenance preference to add (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customer/{shortName}/landlord/tenancy/maintenance/preference"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: tenancyID, var: tenancy_id, required: true}, {name: name, var: name, required: true}, {name: notes, var: notes, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, tenancy_id: $tenancy_id, name: $name, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generate a Tenancy Agreement Copy (PDF)
#
# GET /v2/customer/{shortName}/landlord/tenancyagreement
# Returns: record
# operationId: LandlordController_GetTenancyAgreementReport
export def "landlord-controller-get-tenancy-agreement-report" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --tenancy-id: string # The Tenancy ID (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/landlord/tenancyagreement"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: tenancyID, var: tenancy_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, tenancy_id: $tenancy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Downloads the photo of a property given the photo ID.
#
# GET /v2/customer/{shortName}/photo/download
# Returns: record
# operationId: PhotoController_GetPhotoDownload
export def "photo-controller-get-photo-download" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --photo-id: string # The unique ID of the photo on the property (required)
  --width: int # An optional parameter specifying the image width (format: int32)
  --height: int # An optional parameter specifying the image height (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/photo/download"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: photoID, var: photo_id, required: true}, {name: width, var: width}, {name: height, var: height}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, photo_id: $photo_id, width: $width, height: $height
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# A collection showing all the photos linked to a specific block, property or room
#
# GET /v2/customer/{shortName}/property/{propertyID}/photos
# Returns: record<Count: int, Data: table<ETag: string, FileName: string, OID: string, PhotoType: string>>
# operationId: PropertyController_GetPropertiesPhotos
export def "property-controller-get-properties-photos" [
  short_name: string
  property_id: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/property/{propertyID}/photos"
    path_params: [{name: shortName, var: short_name}, {name: propertyID, var: property_id}]
    query: [{name: token, var: qp_token, required: true}, {name: offset, var: offset, required: true}, {name: count, var: count, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, property_id: $property_id, qp_token: $qp_token, offset: $offset, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Logout a customer previously logged in via the Login endpoint.
#
# DELETE /v2/customer/{shortName}/session
# operationId: SessionController_Logout
export def "session-controller-logout" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/customer/{shortName}/session"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the currently logged on customer.
#
# GET /v2/customer/{shortName}/session
# Returns: string
# operationId: SessionController_GetSessionInfo
export def "session-controller-get-session-info" [
  short_name: string
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
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/customer/{shortName}/session"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Login as a customer given their username and password.
#
# POST /v2/customer/{shortName}/session
# Returns: string
# operationId: SessionController_Login
export def "session-controller-login" [
  short_name: string
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
  --username: string # The user's username. (required)
  --password: string # The user's password. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customer/{shortName}/session"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: username, var: username, required: true}, {name: password, var: password, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: apikey
  } {
    short_name: $short_name, username: $username, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send a request to the in-tray to create a landlord login.
#
# POST /v2/customer/{shortName}/session/createlandlordlogin
# operationId: SessionController_CreateLandlordLogin
export def "session-controller-create-landlord-login" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the landlord (required)
  --title: string # The title of the landlord (required)
  --forename: string # The forename of the landlord (required)
  --surname: string # The surname of the landlord (required)
  --property-address: string # Address of the property linked to the landlord (required)
  --contact-details: string # Contact details of the landlord (required)
  --branch-id: string # (Optional) The branch ID linked to the login. This will determine which in tray the request display in
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customer/{shortName}/session/createlandlordlogin"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: email, var: email, required: true}, {name: title, var: title, required: true}, {name: forename, var: forename, required: true}, {name: surname, var: surname, required: true}, {name: propertyAddress, var: property_address, required: true}, {name: contactDetails, var: contact_details, required: true}, {name: branchID, var: branch_id}]
    accept: ["application/json"]
    ok: [204]
    auth: apikey
  } {
    short_name: $short_name, email: $email, title: $title, forename: $forename, surname: $surname, property_address: $property_address, contact_details: $contact_details, branch_id: $branch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the password of a customer given their existing and new password.
#
# PUT /v2/customer/{shortName}/session/password
# operationId: SessionController_ChangePassword
export def "session-controller-change-password" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The login token returned from the /session POST call (required) (spec name: token)
  --old-password: string # The customer's existing password. (required)
  --new-password: string # The customer's new password. (required)
]: nothing -> any {
  http-request {
    method: put
    path: "/v2/customer/{shortName}/session/password"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: token, var: qp_token, required: true}, {name: oldPassword, var: old_password, required: true}, {name: newPassword, var: new_password, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: apikey
  } {
    short_name: $short_name, qp_token: $qp_token, old_password: $old_password, new_password: $new_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the customer's password. An email will be sent out to reset.
#
# POST /v2/customer/{shortName}/session/resetpassword
# operationId: SessionController_ResetPassword
export def "session-controller-reset-password" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The login Email Address. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customer/{shortName}/session/resetpassword"
    path_params: [{name: shortName, var: short_name}]
    query: [{name: email, var: email, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: apikey
  } {
    short_name: $short_name, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
