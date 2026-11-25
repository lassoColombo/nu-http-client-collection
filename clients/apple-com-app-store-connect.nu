# Auto-generated client for App Store Connect API v1.4.1
# Source: https://api.apis.guru/v2/specs/apple.com/app-store-connect/1.4.1/openapi.json
# Auth: --token flag or $env.APP_STORE_CONNECT_API_TOKEN

const CLIENT = {
  base_url: "https://api.appstoreconnect.apple.com"
  token_env_var: "APP_STORE_CONNECT_API_TOKEN"
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

def base-url-completer [] { ["https://api.appstoreconnect.apple.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    age-rating-declarations-update-instance: "record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-categories-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-categories-get-instance: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-categories-parent-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-categories-subcategories-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-encryption-declarations-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-encryption-declarations-get-instance: "record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-encryption-declarations-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-info-localizations-create-instance: "record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>"
    app-info-localizations-get-instance: "record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>"
    app-info-localizations-update-instance: "record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>"
    app-infos-get-instance: "record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-update-instance: "record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-age-rating-declaration-get-to-one-related: "record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-infos-app-info-localizations-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-infos-primary-category-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-primary-subcategory-one-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-primary-subcategory-two-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-secondary-category-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-secondary-subcategory-one-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-infos-secondary-subcategory-two-get-to-one-related: "record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-pre-orders-create-instance: "record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>"
    app-pre-orders-get-instance: "record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>"
    app-pre-orders-update-instance: "record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>"
    app-preview-sets-create-instance: "record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-preview-sets-get-instance: "record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-preview-sets-app-previews-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-preview-sets-app-previews-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-previews-create-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>"
    app-previews-get-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>"
    app-previews-update-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>"
    app-price-points-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-price-points-get-instance: "record<data: record<attributes: record<customerPrice: string, proceeds: string>, id: string, links: record<self: string>, relationships: record<priceTier: record, territory: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>"
    app-price-points-territory-get-to-one-related: "record<data: record<attributes: record<currency: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-price-tiers-get-collection: "record<data: table<id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-price-tiers-get-instance: "record<data: record<id: string, links: record<self: string>, relationships: record<pricePoints: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-price-tiers-price-points-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-prices-get-instance: "record<data: record<id: string, links: record<self: string>, relationships: record<app: record, priceTier: record>, type: string>, links: record<self: string>>"
    app-screenshot-sets-create-instance: "record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-screenshot-sets-get-instance: "record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-screenshot-sets-app-screenshots-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-screenshot-sets-app-screenshots-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-screenshots-create-instance: "record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>"
    app-screenshots-get-instance: "record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>"
    app-screenshots-update-instance: "record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>"
    app-store-review-attachments-create-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>"
    app-store-review-attachments-get-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>"
    app-store-review-attachments-update-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>"
    app-store-review-details-create-instance: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-store-review-details-get-instance: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-store-review-details-update-instance: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-store-review-details-app-store-review-attachments-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-store-version-localizations-create-instance: "record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-version-localizations-get-instance: "record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-version-localizations-update-instance: "record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-version-localizations-app-preview-sets-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-store-version-localizations-app-screenshot-sets-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-store-version-phased-releases-create-instance: "record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-store-version-phased-releases-update-instance: "record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-store-version-submissions-create-instance: "record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    app-store-versions-create-instance: "record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-versions-get-instance: "record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-versions-update-instance: "record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-versions-age-rating-declaration-get-to-one-related: "record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-store-versions-app-store-review-detail-get-to-one-related: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    app-store-versions-app-store-version-localizations-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    app-store-versions-app-store-version-phased-release-get-to-one-related: "record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    app-store-versions-app-store-version-submission-get-to-one-related: "record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    app-store-versions-build-get-to-one-related: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    app-store-versions-idfa-declaration-get-to-one-related: "record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    app-store-versions-build-get-to-one-relationship: "record<data: record<id: string, type: string>, links: record<self: string>>"
    app-store-versions-routing-app-coverage-get-to-one-related: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    apps-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-get-instance: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    apps-update-instance: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    apps-app-infos-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-app-store-versions-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-available-territories-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-beta-app-localizations-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-beta-app-review-detail-get-to-one-related: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    apps-beta-groups-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-beta-license-agreement-get-to-one-related: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    apps-builds-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-end-user-license-agreement-get-to-one-related: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>"
    apps-game-center-enabled-versions-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-in-app-purchases-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-perf-power-metrics-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-pre-order-get-to-one-related: "record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>"
    apps-pre-release-versions-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    apps-prices-get-to-many-related: "record<data: table<id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-app-localizations-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-app-localizations-create-instance: "record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-localizations-get-instance: "record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-localizations-update-instance: "record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-localizations-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-app-review-details-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-app-review-details-get-instance: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-review-details-update-instance: "record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-review-details-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-app-review-submissions-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-app-review-submissions-create-instance: "record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-review-submissions-get-instance: "record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-app-review-submissions-build-get-to-one-related: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-build-localizations-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-build-localizations-create-instance: "record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-build-localizations-get-instance: "record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-build-localizations-update-instance: "record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-build-localizations-build-get-to-one-related: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-groups-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-groups-create-instance: "record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-groups-get-instance: "record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-groups-update-instance: "record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-groups-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-groups-beta-testers-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-groups-builds-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-groups-beta-testers-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-groups-builds-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-license-agreements-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-license-agreements-get-instance: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-license-agreements-update-instance: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    beta-license-agreements-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-tester-invitations-create-instance: "record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    beta-testers-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-create-instance: "record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-testers-get-instance: "record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    beta-testers-apps-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-beta-groups-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-builds-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-apps-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-beta-groups-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    beta-testers-builds-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    build-beta-details-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    build-beta-details-get-instance: "record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    build-beta-details-update-instance: "record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    build-beta-details-build-get-to-one-related: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    build-beta-notifications-create-instance: "record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    builds-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-get-instance: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    builds-update-instance: "record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>"
    builds-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    builds-app-encryption-declaration-get-to-one-related: "record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    builds-app-store-version-get-to-one-related: "record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>"
    builds-beta-app-review-submission-get-to-one-related: "record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    builds-beta-build-localizations-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-build-beta-detail-get-to-one-related: "record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    builds-diagnostic-signatures-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, included: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-icons-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-individual-testers-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-perf-power-metrics-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    builds-pre-release-version-get-to-one-related: "record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    builds-app-encryption-declaration-get-to-one-relationship: "record<data: record<id: string, type: string>, links: record<self: string>>"
    builds-individual-testers-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    bundle-id-capabilities-create-instance: "record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    bundle-id-capabilities-update-instance: "record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    bundle-ids-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    bundle-ids-create-instance: "record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>"
    bundle-ids-get-instance: "record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>"
    bundle-ids-update-instance: "record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>"
    bundle-ids-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    bundle-ids-bundle-id-capabilities-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    bundle-ids-profiles-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    certificates-get-collection: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    certificates-create-instance: "record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    certificates-get-instance: "record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    devices-get-collection: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    devices-create-instance: "record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    devices-get-instance: "record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    devices-update-instance: "record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>"
    diagnostic-signatures-logs-get-to-many-related: "record<data: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    end-user-license-agreements-create-instance: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>"
    end-user-license-agreements-get-instance: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>"
    end-user-license-agreements-update-instance: "record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>"
    end-user-license-agreements-territories-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    finance-reports-get-collection: "binary"
    game-center-enabled-versions-compatible-versions-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    game-center-enabled-versions-compatible-versions-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    idfa-declarations-create-instance: "record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    idfa-declarations-update-instance: "record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    in-app-purchases-get-instance: "record<data: record<attributes: record<inAppPurchaseType: string, productId: string, referenceName: string, state: string>, id: string, links: record<self: string>, relationships: record<apps: record>, type: string>, links: record<self: string>>"
    pre-release-versions-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    pre-release-versions-get-instance: "record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>"
    pre-release-versions-app-get-to-one-related: "record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>"
    pre-release-versions-builds-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    profiles-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    profiles-create-instance: "record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>>"
    profiles-get-instance: "record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>>"
    profiles-bundle-id-get-to-one-related: "record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>"
    profiles-certificates-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    profiles-devices-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    routing-app-coverages-create-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    routing-app-coverages-get-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    routing-app-coverages-update-instance: "record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>"
    sales-reports-get-collection: "binary"
    territories-get-collection: "record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    user-invitations-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    user-invitations-create-instance: "record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    user-invitations-get-instance: "record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    user-invitations-visible-apps-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    users-get-collection: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    users-get-instance: "record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    users-update-instance: "record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>"
    users-visible-apps-get-to-many-relationship: "record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
    users-visible-apps-get-to-many-related: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["age-rating-declarations-update-instance" "app-categories-get-collection" "app-categories-get-instance" "app-categories-parent-get-to-one-related" "app-categories-subcategories-get-to-many-related" "app-encryption-declarations-get-collection" "app-encryption-declarations-get-instance" "app-encryption-declarations-app-get-to-one-related" "app-encryption-declarations-builds-create-to-many-relationship" "app-info-localizations-create-instance" "app-info-localizations-delete-instance" "app-info-localizations-get-instance" "app-info-localizations-update-instance" "app-infos-get-instance" "app-infos-update-instance" "app-infos-age-rating-declaration-get-to-one-related" "app-infos-app-info-localizations-get-to-many-related" "app-infos-primary-category-get-to-one-related" "app-infos-primary-subcategory-one-get-to-one-related" "app-infos-primary-subcategory-two-get-to-one-related" "app-infos-secondary-category-get-to-one-related" "app-infos-secondary-subcategory-one-get-to-one-related" "app-infos-secondary-subcategory-two-get-to-one-related" "app-pre-orders-create-instance" "app-pre-orders-delete-instance" "app-pre-orders-get-instance" "app-pre-orders-update-instance" "app-preview-sets-create-instance" "app-preview-sets-delete-instance" "app-preview-sets-get-instance" "app-preview-sets-app-previews-get-to-many-related" "app-preview-sets-app-previews-get-to-many-relationship" "app-preview-sets-app-previews-replace-to-many-relationship" "app-previews-create-instance" "app-previews-delete-instance" "app-previews-get-instance" "app-previews-update-instance" "app-price-points-get-collection" "app-price-points-get-instance" "app-price-points-territory-get-to-one-related" "app-price-tiers-get-collection" "app-price-tiers-get-instance" "app-price-tiers-price-points-get-to-many-related" "app-prices-get-instance" "app-screenshot-sets-create-instance" "app-screenshot-sets-delete-instance" "app-screenshot-sets-get-instance" "app-screenshot-sets-app-screenshots-get-to-many-related" "app-screenshot-sets-app-screenshots-get-to-many-relationship" "app-screenshot-sets-app-screenshots-replace-to-many-relationship" "app-screenshots-create-instance" "app-screenshots-delete-instance" "app-screenshots-get-instance" "app-screenshots-update-instance" "app-store-review-attachments-create-instance" "app-store-review-attachments-delete-instance" "app-store-review-attachments-get-instance" "app-store-review-attachments-update-instance" "app-store-review-details-create-instance" "app-store-review-details-get-instance" "app-store-review-details-update-instance" "app-store-review-details-app-store-review-attachments-get-to-many-related" "app-store-version-localizations-create-instance" "app-store-version-localizations-delete-instance" "app-store-version-localizations-get-instance" "app-store-version-localizations-update-instance" "app-store-version-localizations-app-preview-sets-get-to-many-related" "app-store-version-localizations-app-screenshot-sets-get-to-many-related" "app-store-version-phased-releases-create-instance" "app-store-version-phased-releases-delete-instance" "app-store-version-phased-releases-update-instance" "app-store-version-submissions-create-instance" "app-store-version-submissions-delete-instance" "app-store-versions-create-instance" "app-store-versions-delete-instance" "app-store-versions-get-instance" "app-store-versions-update-instance" "app-store-versions-age-rating-declaration-get-to-one-related" "app-store-versions-app-store-review-detail-get-to-one-related" "app-store-versions-app-store-version-localizations-get-to-many-related" "app-store-versions-app-store-version-phased-release-get-to-one-related" "app-store-versions-app-store-version-submission-get-to-one-related" "app-store-versions-build-get-to-one-related" "app-store-versions-idfa-declaration-get-to-one-related" "app-store-versions-build-get-to-one-relationship" "app-store-versions-build-update-to-one-relationship" "app-store-versions-routing-app-coverage-get-to-one-related" "apps-get-collection" "apps-get-instance" "apps-update-instance" "apps-app-infos-get-to-many-related" "apps-app-store-versions-get-to-many-related" "apps-available-territories-get-to-many-related" "apps-beta-app-localizations-get-to-many-related" "apps-beta-app-review-detail-get-to-one-related" "apps-beta-groups-get-to-many-related" "apps-beta-license-agreement-get-to-one-related" "apps-builds-get-to-many-related" "apps-end-user-license-agreement-get-to-one-related" "apps-game-center-enabled-versions-get-to-many-related" "apps-in-app-purchases-get-to-many-related" "apps-perf-power-metrics-get-to-many-related" "apps-pre-order-get-to-one-related" "apps-pre-release-versions-get-to-many-related" "apps-prices-get-to-many-related" "apps-beta-testers-delete-to-many-relationship" "beta-app-localizations-get-collection" "beta-app-localizations-create-instance" "beta-app-localizations-delete-instance" "beta-app-localizations-get-instance" "beta-app-localizations-update-instance" "beta-app-localizations-app-get-to-one-related" "beta-app-review-details-get-collection" "beta-app-review-details-get-instance" "beta-app-review-details-update-instance" "beta-app-review-details-app-get-to-one-related" "beta-app-review-submissions-get-collection" "beta-app-review-submissions-create-instance" "beta-app-review-submissions-get-instance" "beta-app-review-submissions-build-get-to-one-related" "beta-build-localizations-get-collection" "beta-build-localizations-create-instance" "beta-build-localizations-delete-instance" "beta-build-localizations-get-instance" "beta-build-localizations-update-instance" "beta-build-localizations-build-get-to-one-related" "beta-groups-get-collection" "beta-groups-create-instance" "beta-groups-delete-instance" "beta-groups-get-instance" "beta-groups-update-instance" "beta-groups-app-get-to-one-related" "beta-groups-beta-testers-get-to-many-related" "beta-groups-builds-get-to-many-related" "beta-groups-beta-testers-delete-to-many-relationship" "beta-groups-beta-testers-get-to-many-relationship" "beta-groups-beta-testers-create-to-many-relationship" "beta-groups-builds-delete-to-many-relationship" "beta-groups-builds-get-to-many-relationship" "beta-groups-builds-create-to-many-relationship" "beta-license-agreements-get-collection" "beta-license-agreements-get-instance" "beta-license-agreements-update-instance" "beta-license-agreements-app-get-to-one-related" "beta-tester-invitations-create-instance" "beta-testers-get-collection" "beta-testers-create-instance" "beta-testers-delete-instance" "beta-testers-get-instance" "beta-testers-apps-get-to-many-related" "beta-testers-beta-groups-get-to-many-related" "beta-testers-builds-get-to-many-related" "beta-testers-apps-delete-to-many-relationship" "beta-testers-apps-get-to-many-relationship" "beta-testers-beta-groups-delete-to-many-relationship" "beta-testers-beta-groups-get-to-many-relationship" "beta-testers-beta-groups-create-to-many-relationship" "beta-testers-builds-delete-to-many-relationship" "beta-testers-builds-get-to-many-relationship" "beta-testers-builds-create-to-many-relationship" "build-beta-details-get-collection" "build-beta-details-get-instance" "build-beta-details-update-instance" "build-beta-details-build-get-to-one-related" "build-beta-notifications-create-instance" "builds-get-collection" "builds-get-instance" "builds-update-instance" "builds-app-get-to-one-related" "builds-app-encryption-declaration-get-to-one-related" "builds-app-store-version-get-to-one-related" "builds-beta-app-review-submission-get-to-one-related" "builds-beta-build-localizations-get-to-many-related" "builds-build-beta-detail-get-to-one-related" "builds-diagnostic-signatures-get-to-many-related" "builds-icons-get-to-many-related" "builds-individual-testers-get-to-many-related" "builds-perf-power-metrics-get-to-many-related" "builds-pre-release-version-get-to-one-related" "builds-app-encryption-declaration-get-to-one-relationship" "builds-app-encryption-declaration-update-to-one-relationship" "builds-beta-groups-delete-to-many-relationship" "builds-beta-groups-create-to-many-relationship" "builds-individual-testers-delete-to-many-relationship" "builds-individual-testers-get-to-many-relationship" "builds-individual-testers-create-to-many-relationship" "bundle-id-capabilities-create-instance" "bundle-id-capabilities-delete-instance" "bundle-id-capabilities-update-instance" "bundle-ids-get-collection" "bundle-ids-create-instance" "bundle-ids-delete-instance" "bundle-ids-get-instance" "bundle-ids-update-instance" "bundle-ids-app-get-to-one-related" "bundle-ids-bundle-id-capabilities-get-to-many-related" "bundle-ids-profiles-get-to-many-related" "certificates-get-collection" "certificates-create-instance" "certificates-delete-instance" "certificates-get-instance" "devices-get-collection" "devices-create-instance" "devices-get-instance" "devices-update-instance" "diagnostic-signatures-logs-get-to-many-related" "end-user-license-agreements-create-instance" "end-user-license-agreements-delete-instance" "end-user-license-agreements-get-instance" "end-user-license-agreements-update-instance" "end-user-license-agreements-territories-get-to-many-related" "finance-reports-get-collection" "game-center-enabled-versions-compatible-versions-get-to-many-related" "game-center-enabled-versions-compatible-versions-delete-to-many-relationship" "game-center-enabled-versions-compatible-versions-get-to-many-relationship" "game-center-enabled-versions-compatible-versions-replace-to-many-relationship" "game-center-enabled-versions-compatible-versions-create-to-many-relationship" "idfa-declarations-create-instance" "idfa-declarations-delete-instance" "idfa-declarations-update-instance" "in-app-purchases-get-instance" "pre-release-versions-get-collection" "pre-release-versions-get-instance" "pre-release-versions-app-get-to-one-related" "pre-release-versions-builds-get-to-many-related" "profiles-get-collection" "profiles-create-instance" "profiles-delete-instance" "profiles-get-instance" "profiles-bundle-id-get-to-one-related" "profiles-certificates-get-to-many-related" "profiles-devices-get-to-many-related" "routing-app-coverages-create-instance" "routing-app-coverages-delete-instance" "routing-app-coverages-get-instance" "routing-app-coverages-update-instance" "sales-reports-get-collection" "territories-get-collection" "user-invitations-get-collection" "user-invitations-create-instance" "user-invitations-delete-instance" "user-invitations-get-instance" "user-invitations-visible-apps-get-to-many-related" "users-get-collection" "users-delete-instance" "users-get-instance" "users-update-instance" "users-visible-apps-delete-to-many-relationship" "users-visible-apps-get-to-many-relationship" "users-visible-apps-replace-to-many-relationship" "users-visible-apps-create-to-many-relationship" "users-visible-apps-get-to-many-related" "commands"] | sort) } | get name | first)
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

# PATCH /v1/ageRatingDeclarations/{id}
#
# Returns: record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: ageRatingDeclarations-update_instance
export def "age-rating-declarations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "ageRatingDeclarations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/ageRatingDeclarations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appCategories
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appCategories-get_collection
export def "app-categories-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platforms: list<string> # filter by attribute 'platforms'
  --exists-parent: list<string> # filter by existence or non-existence of related 'parent'
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --limit-subcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appCategories"
    query: [{name: "filter[platforms]", var: filter_platforms, style: csv}, {name: "exists[parent]", var: exists_parent, style: csv}, {name: "fields[appCategories]", var: fields_app_categories, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "limit[subcategories]", var: limit_subcategories}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_platforms: $filter_platforms, exists_parent: $exists_parent, fields_app_categories: $fields_app_categories, limit: $limit, include: $include, limit_subcategories: $limit_subcategories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appCategories/{id}
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appCategories-get_instance
export def "app-categories-get-instance" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
  --include: list<string> # comma-separated list of relationships to include
  --limit-subcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appCategories/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}, {name: include, var: include, style: csv}, {name: "limit[subcategories]", var: limit_subcategories}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories, include: $include, limit_subcategories: $limit_subcategories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appCategories/{id}/parent
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appCategories-parent-get_to_one_related
export def "app-categories-parent-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appCategories/{id}/parent"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appCategories/{id}/subcategories
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appCategories-subcategories-get_to_many_related
export def "app-categories-subcategories-get-to-many-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appCategories/{id}/subcategories"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appEncryptionDeclarations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appEncryptionDeclarations-get_collection
export def "app-encryption-declarations-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --filter-builds: list<string> # filter by id(s) of related 'builds'
  --fields-app-encryption-declarations: list<string> # the fields to include for returned resources of type appEncryptionDeclarations
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appEncryptionDeclarations"
    query: [{name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "filter[builds]", var: filter_builds, style: csv}, {name: "fields[appEncryptionDeclarations]", var: fields_app_encryption_declarations, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_platform: $filter_platform, filter_app: $filter_app, filter_builds: $filter_builds, fields_app_encryption_declarations: $fields_app_encryption_declarations, limit: $limit, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appEncryptionDeclarations/{id}
#
# Returns: record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appEncryptionDeclarations-get_instance
export def "app-encryption-declarations-get-instance" [
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
  --fields-app-encryption-declarations: list<string> # the fields to include for returned resources of type appEncryptionDeclarations
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appEncryptionDeclarations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appEncryptionDeclarations]", var: fields_app_encryption_declarations, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_encryption_declarations: $fields_app_encryption_declarations, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appEncryptionDeclarations/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appEncryptionDeclarations-app-get_to_one_related
export def "app-encryption-declarations-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appEncryptionDeclarations/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appEncryptionDeclarations/{id}/relationships/builds
#
# operationId: appEncryptionDeclarations-builds-create_to_many_relationship
export def "app-encryption-declarations-builds-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/appEncryptionDeclarations/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appInfoLocalizations
#
# Returns: record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>
# operationId: appInfoLocalizations-create_instance
export def "app-info-localizations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appInfoLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appInfoLocalizations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appInfoLocalizations/{id}
#
# operationId: appInfoLocalizations-delete_instance
export def "app-info-localizations-delete-instance" [
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
    path: "/v1/appInfoLocalizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfoLocalizations/{id}
#
# Returns: record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>
# operationId: appInfoLocalizations-get_instance
export def "app-info-localizations-get-instance" [
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
  --fields-app-info-localizations: list<string> # the fields to include for returned resources of type appInfoLocalizations
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfoLocalizations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appInfoLocalizations]", var: fields_app_info_localizations, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_info_localizations: $fields_app_info_localizations, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appInfoLocalizations/{id}
#
# Returns: record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>>
# operationId: appInfoLocalizations-update_instance
export def "app-info-localizations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appInfoLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appInfoLocalizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}
#
# Returns: record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-get_instance
export def "app-infos-get-instance" [
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
  --fields-app-infos: list<string> # the fields to include for returned resources of type appInfos
  --include: list<string> # comma-separated list of relationships to include
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
  --fields-app-info-localizations: list<string> # the fields to include for returned resources of type appInfoLocalizations
  --limit-app-info-localizations: int # maximum number of related appInfoLocalizations returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appInfos]", var: fields_app_infos, style: csv}, {name: include, var: include, style: csv}, {name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}, {name: "fields[appCategories]", var: fields_app_categories, style: csv}, {name: "fields[appInfoLocalizations]", var: fields_app_info_localizations, style: csv}, {name: "limit[appInfoLocalizations]", var: limit_app_info_localizations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_infos: $fields_app_infos, include: $include, fields_age_rating_declarations: $fields_age_rating_declarations, fields_app_categories: $fields_app_categories, fields_app_info_localizations: $fields_app_info_localizations, limit_app_info_localizations: $limit_app_info_localizations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appInfos/{id}
#
# Returns: record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-update_instance
export def "app-infos-update-instance" [
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
  data: record # shape: {id: string, relationships?: record, type: "appInfos"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appInfos/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/ageRatingDeclaration
#
# Returns: record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appInfos-ageRatingDeclaration-get_to_one_related
export def "app-infos-age-rating-declaration-get-to-one-related" [
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
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/ageRatingDeclaration"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_age_rating_declarations: $fields_age_rating_declarations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/appInfoLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appInfos-appInfoLocalizations-get_to_many_related
export def "app-infos-app-info-localizations-get-to-many-related" [
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
  --filter-locale: list<string> # filter by attribute 'locale'
  --fields-app-infos: list<string> # the fields to include for returned resources of type appInfos
  --fields-app-info-localizations: list<string> # the fields to include for returned resources of type appInfoLocalizations
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/appInfoLocalizations"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[locale]", var: filter_locale, style: csv}, {name: "fields[appInfos]", var: fields_app_infos, style: csv}, {name: "fields[appInfoLocalizations]", var: fields_app_info_localizations, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_locale: $filter_locale, fields_app_infos: $fields_app_infos, fields_app_info_localizations: $fields_app_info_localizations, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/primaryCategory
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-primaryCategory-get_to_one_related
export def "app-infos-primary-category-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/primaryCategory"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/primarySubcategoryOne
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-primarySubcategoryOne-get_to_one_related
export def "app-infos-primary-subcategory-one-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/primarySubcategoryOne"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/primarySubcategoryTwo
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-primarySubcategoryTwo-get_to_one_related
export def "app-infos-primary-subcategory-two-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/primarySubcategoryTwo"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/secondaryCategory
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-secondaryCategory-get_to_one_related
export def "app-infos-secondary-category-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/secondaryCategory"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/secondarySubcategoryOne
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-secondarySubcategoryOne-get_to_one_related
export def "app-infos-secondary-subcategory-one-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/secondarySubcategoryOne"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appInfos/{id}/secondarySubcategoryTwo
#
# Returns: record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appInfos-secondarySubcategoryTwo-get_to_one_related
export def "app-infos-secondary-subcategory-two-get-to-one-related" [
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
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appInfos/{id}/secondarySubcategoryTwo"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appCategories]", var: fields_app_categories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_categories: $fields_app_categories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appPreOrders
#
# Returns: record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>
# operationId: appPreOrders-create_instance
export def "app-pre-orders-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appPreOrders"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appPreOrders"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appPreOrders/{id}
#
# operationId: appPreOrders-delete_instance
export def "app-pre-orders-delete-instance" [
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
    path: "/v1/appPreOrders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPreOrders/{id}
#
# Returns: record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>
# operationId: appPreOrders-get_instance
export def "app-pre-orders-get-instance" [
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
  --fields-app-pre-orders: list<string> # the fields to include for returned resources of type appPreOrders
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPreOrders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPreOrders]", var: fields_app_pre_orders, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_pre_orders: $fields_app_pre_orders, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appPreOrders/{id}
#
# Returns: record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>
# operationId: appPreOrders-update_instance
export def "app-pre-orders-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appPreOrders"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appPreOrders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appPreviewSets
#
# Returns: record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appPreviewSets-create_instance
export def "app-preview-sets-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appPreviewSets"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appPreviewSets"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appPreviewSets/{id}
#
# operationId: appPreviewSets-delete_instance
export def "app-preview-sets-delete-instance" [
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
    path: "/v1/appPreviewSets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPreviewSets/{id}
#
# Returns: record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appPreviewSets-get_instance
export def "app-preview-sets-get-instance" [
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
  --fields-app-preview-sets: list<string> # the fields to include for returned resources of type appPreviewSets
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-previews: list<string> # the fields to include for returned resources of type appPreviews
  --limit-app-previews: int # maximum number of related appPreviews returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPreviewSets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPreviewSets]", var: fields_app_preview_sets, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appPreviews]", var: fields_app_previews, style: csv}, {name: "limit[appPreviews]", var: limit_app_previews}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_preview_sets: $fields_app_preview_sets, include: $include, fields_app_previews: $fields_app_previews, limit_app_previews: $limit_app_previews
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPreviewSets/{id}/appPreviews
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appPreviewSets-appPreviews-get_to_many_related
export def "app-preview-sets-app-previews-get-to-many-related" [
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
  --fields-app-previews: list<string> # the fields to include for returned resources of type appPreviews
  --fields-app-preview-sets: list<string> # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPreviewSets/{id}/appPreviews"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPreviews]", var: fields_app_previews, style: csv}, {name: "fields[appPreviewSets]", var: fields_app_preview_sets, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_previews: $fields_app_previews, fields_app_preview_sets: $fields_app_preview_sets, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPreviewSets/{id}/relationships/appPreviews
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appPreviewSets-appPreviews-get_to_many_relationship
export def "app-preview-sets-app-previews-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPreviewSets/{id}/relationships/appPreviews"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appPreviewSets/{id}/relationships/appPreviews
#
# operationId: appPreviewSets-appPreviews-replace_to_many_relationship
export def "app-preview-sets-app-previews-replace-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "appPreviews"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/appPreviewSets/{id}/relationships/appPreviews"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appPreviews
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>
# operationId: appPreviews-create_instance
export def "app-previews-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appPreviews"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appPreviews"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appPreviews/{id}
#
# operationId: appPreviews-delete_instance
export def "app-previews-delete-instance" [
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
    path: "/v1/appPreviews/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPreviews/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>
# operationId: appPreviews-get_instance
export def "app-previews-get-instance" [
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
  --fields-app-previews: list<string> # the fields to include for returned resources of type appPreviews
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPreviews/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPreviews]", var: fields_app_previews, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_previews: $fields_app_previews, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appPreviews/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>>
# operationId: appPreviews-update_instance
export def "app-previews-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appPreviews"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appPreviews/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPricePoints
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appPricePoints-get_collection
export def "app-price-points-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-price-tier: list<string> # filter by id(s) of related 'priceTier'
  --filter-territory: list<string> # filter by id(s) of related 'territory'
  --fields-app-price-points: list<string> # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-territories: list<string> # the fields to include for returned resources of type territories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPricePoints"
    query: [{name: "filter[priceTier]", var: filter_price_tier, style: csv}, {name: "filter[territory]", var: filter_territory, style: csv}, {name: "fields[appPricePoints]", var: fields_app_price_points, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[territories]", var: fields_territories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_price_tier: $filter_price_tier, filter_territory: $filter_territory, fields_app_price_points: $fields_app_price_points, limit: $limit, include: $include, fields_territories: $fields_territories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPricePoints/{id}
#
# Returns: record<data: record<attributes: record<customerPrice: string, proceeds: string>, id: string, links: record<self: string>, relationships: record<priceTier: record, territory: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>
# operationId: appPricePoints-get_instance
export def "app-price-points-get-instance" [
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
  --fields-app-price-points: list<string> # the fields to include for returned resources of type appPricePoints
  --include: list<string> # comma-separated list of relationships to include
  --fields-territories: list<string> # the fields to include for returned resources of type territories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPricePoints/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPricePoints]", var: fields_app_price_points, style: csv}, {name: include, var: include, style: csv}, {name: "fields[territories]", var: fields_territories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_price_points: $fields_app_price_points, include: $include, fields_territories: $fields_territories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPricePoints/{id}/territory
#
# Returns: record<data: record<attributes: record<currency: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appPricePoints-territory-get_to_one_related
export def "app-price-points-territory-get-to-one-related" [
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
  --fields-territories: list<string> # the fields to include for returned resources of type territories
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPricePoints/{id}/territory"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[territories]", var: fields_territories, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_territories: $fields_territories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPriceTiers
#
# Returns: record<data: table<id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appPriceTiers-get_collection
export def "app-price-tiers-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-id: list<string> # filter by id(s)
  --fields-app-price-tiers: list<string> # the fields to include for returned resources of type appPriceTiers
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-price-points: list<string> # the fields to include for returned resources of type appPricePoints
  --limit-price-points: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPriceTiers"
    query: [{name: "filter[id]", var: filter_id, style: csv}, {name: "fields[appPriceTiers]", var: fields_app_price_tiers, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[appPricePoints]", var: fields_app_price_points, style: csv}, {name: "limit[pricePoints]", var: limit_price_points}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_id: $filter_id, fields_app_price_tiers: $fields_app_price_tiers, limit: $limit, include: $include, fields_app_price_points: $fields_app_price_points, limit_price_points: $limit_price_points
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPriceTiers/{id}
#
# Returns: record<data: record<id: string, links: record<self: string>, relationships: record<pricePoints: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appPriceTiers-get_instance
export def "app-price-tiers-get-instance" [
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
  --fields-app-price-tiers: list<string> # the fields to include for returned resources of type appPriceTiers
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-price-points: list<string> # the fields to include for returned resources of type appPricePoints
  --limit-price-points: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPriceTiers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPriceTiers]", var: fields_app_price_tiers, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appPricePoints]", var: fields_app_price_points, style: csv}, {name: "limit[pricePoints]", var: limit_price_points}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_price_tiers: $fields_app_price_tiers, include: $include, fields_app_price_points: $fields_app_price_points, limit_price_points: $limit_price_points
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPriceTiers/{id}/pricePoints
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appPriceTiers-pricePoints-get_to_many_related
export def "app-price-tiers-price-points-get-to-many-related" [
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
  --fields-app-price-points: list<string> # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPriceTiers/{id}/pricePoints"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPricePoints]", var: fields_app_price_points, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_price_points: $fields_app_price_points, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appPrices/{id}
#
# Returns: record<data: record<id: string, links: record<self: string>, relationships: record<app: record, priceTier: record>, type: string>, links: record<self: string>>
# operationId: appPrices-get_instance
export def "app-prices-get-instance" [
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
  --fields-app-prices: list<string> # the fields to include for returned resources of type appPrices
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appPrices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPrices]", var: fields_app_prices, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_prices: $fields_app_prices, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appScreenshotSets
#
# Returns: record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appScreenshotSets-create_instance
export def "app-screenshot-sets-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appScreenshotSets"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appScreenshotSets"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appScreenshotSets/{id}
#
# operationId: appScreenshotSets-delete_instance
export def "app-screenshot-sets-delete-instance" [
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
    path: "/v1/appScreenshotSets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appScreenshotSets/{id}
#
# Returns: record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appScreenshotSets-get_instance
export def "app-screenshot-sets-get-instance" [
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
  --fields-app-screenshot-sets: list<string> # the fields to include for returned resources of type appScreenshotSets
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-screenshots: list<string> # the fields to include for returned resources of type appScreenshots
  --limit-app-screenshots: int # maximum number of related appScreenshots returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appScreenshotSets/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appScreenshotSets]", var: fields_app_screenshot_sets, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appScreenshots]", var: fields_app_screenshots, style: csv}, {name: "limit[appScreenshots]", var: limit_app_screenshots}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_screenshot_sets: $fields_app_screenshot_sets, include: $include, fields_app_screenshots: $fields_app_screenshots, limit_app_screenshots: $limit_app_screenshots
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appScreenshotSets/{id}/appScreenshots
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appScreenshotSets-appScreenshots-get_to_many_related
export def "app-screenshot-sets-app-screenshots-get-to-many-related" [
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
  --fields-app-screenshot-sets: list<string> # the fields to include for returned resources of type appScreenshotSets
  --fields-app-screenshots: list<string> # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appScreenshotSets/{id}/appScreenshots"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appScreenshotSets]", var: fields_app_screenshot_sets, style: csv}, {name: "fields[appScreenshots]", var: fields_app_screenshots, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_screenshot_sets: $fields_app_screenshot_sets, fields_app_screenshots: $fields_app_screenshots, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appScreenshotSets/{id}/relationships/appScreenshots
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appScreenshotSets-appScreenshots-get_to_many_relationship
export def "app-screenshot-sets-app-screenshots-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appScreenshotSets/{id}/relationships/appScreenshots"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots
#
# operationId: appScreenshotSets-appScreenshots-replace_to_many_relationship
export def "app-screenshot-sets-app-screenshots-replace-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "appScreenshots"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/appScreenshotSets/{id}/relationships/appScreenshots"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appScreenshots
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>
# operationId: appScreenshots-create_instance
export def "app-screenshots-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appScreenshots"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appScreenshots"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appScreenshots/{id}
#
# operationId: appScreenshots-delete_instance
export def "app-screenshots-delete-instance" [
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
    path: "/v1/appScreenshots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appScreenshots/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>
# operationId: appScreenshots-get_instance
export def "app-screenshots-get-instance" [
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
  --fields-app-screenshots: list<string> # the fields to include for returned resources of type appScreenshots
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appScreenshots/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appScreenshots]", var: fields_app_screenshots, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_screenshots: $fields_app_screenshots, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appScreenshots/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>>
# operationId: appScreenshots-update_instance
export def "app-screenshots-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appScreenshots"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appScreenshots/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreReviewAttachments
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>
# operationId: appStoreReviewAttachments-create_instance
export def "app-store-review-attachments-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreReviewAttachments"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreReviewAttachments"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appStoreReviewAttachments/{id}
#
# operationId: appStoreReviewAttachments-delete_instance
export def "app-store-review-attachments-delete-instance" [
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
    path: "/v1/appStoreReviewAttachments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreReviewAttachments/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>
# operationId: appStoreReviewAttachments-get_instance
export def "app-store-review-attachments-get-instance" [
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
  --fields-app-store-review-attachments: list<string> # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreReviewAttachments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreReviewAttachments]", var: fields_app_store_review_attachments, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_review_attachments: $fields_app_store_review_attachments, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreReviewAttachments/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>>
# operationId: appStoreReviewAttachments-update_instance
export def "app-store-review-attachments-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appStoreReviewAttachments"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appStoreReviewAttachments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreReviewDetails
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appStoreReviewDetails-create_instance
export def "app-store-review-details-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appStoreReviewDetails"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreReviewDetails"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreReviewDetails/{id}
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appStoreReviewDetails-get_instance
export def "app-store-review-details-get-instance" [
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
  --fields-app-store-review-details: list<string> # the fields to include for returned resources of type appStoreReviewDetails
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-store-review-attachments: list<string> # the fields to include for returned resources of type appStoreReviewAttachments
  --limit-app-store-review-attachments: int # maximum number of related appStoreReviewAttachments returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreReviewDetails/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreReviewDetails]", var: fields_app_store_review_details, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appStoreReviewAttachments]", var: fields_app_store_review_attachments, style: csv}, {name: "limit[appStoreReviewAttachments]", var: limit_app_store_review_attachments}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_review_details: $fields_app_store_review_details, include: $include, fields_app_store_review_attachments: $fields_app_store_review_attachments, limit_app_store_review_attachments: $limit_app_store_review_attachments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreReviewDetails/{id}
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appStoreReviewDetails-update_instance
export def "app-store-review-details-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appStoreReviewDetails"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appStoreReviewDetails/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreReviewDetails/{id}/appStoreReviewAttachments
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appStoreReviewDetails-appStoreReviewAttachments-get_to_many_related
export def "app-store-review-details-app-store-review-attachments-get-to-many-related" [
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
  --fields-app-store-review-details: list<string> # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-review-attachments: list<string> # the fields to include for returned resources of type appStoreReviewAttachments
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreReviewDetails/{id}/appStoreReviewAttachments"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreReviewDetails]", var: fields_app_store_review_details, style: csv}, {name: "fields[appStoreReviewAttachments]", var: fields_app_store_review_attachments, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_review_details: $fields_app_store_review_details, fields_app_store_review_attachments: $fields_app_store_review_attachments, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreVersionLocalizations
#
# Returns: record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersionLocalizations-create_instance
export def "app-store-version-localizations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreVersionLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreVersionLocalizations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appStoreVersionLocalizations/{id}
#
# operationId: appStoreVersionLocalizations-delete_instance
export def "app-store-version-localizations-delete-instance" [
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
    path: "/v1/appStoreVersionLocalizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersionLocalizations/{id}
#
# Returns: record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersionLocalizations-get_instance
export def "app-store-version-localizations-get-instance" [
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
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-screenshot-sets: list<string> # the fields to include for returned resources of type appScreenshotSets
  --fields-app-preview-sets: list<string> # the fields to include for returned resources of type appPreviewSets
  --limit-app-preview-sets: int # maximum number of related appPreviewSets returned (when they are included)
  --limit-app-screenshot-sets: int # maximum number of related appScreenshotSets returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersionLocalizations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appScreenshotSets]", var: fields_app_screenshot_sets, style: csv}, {name: "fields[appPreviewSets]", var: fields_app_preview_sets, style: csv}, {name: "limit[appPreviewSets]", var: limit_app_preview_sets}, {name: "limit[appScreenshotSets]", var: limit_app_screenshot_sets}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_version_localizations: $fields_app_store_version_localizations, include: $include, fields_app_screenshot_sets: $fields_app_screenshot_sets, fields_app_preview_sets: $fields_app_preview_sets, limit_app_preview_sets: $limit_app_preview_sets, limit_app_screenshot_sets: $limit_app_screenshot_sets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreVersionLocalizations/{id}
#
# Returns: record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersionLocalizations-update_instance
export def "app-store-version-localizations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appStoreVersionLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appStoreVersionLocalizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersionLocalizations/{id}/appPreviewSets
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appStoreVersionLocalizations-appPreviewSets-get_to_many_related
export def "app-store-version-localizations-app-preview-sets-get-to-many-related" [
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
  --filter-preview-type: list<string> # filter by attribute 'previewType'
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-app-previews: list<string> # the fields to include for returned resources of type appPreviews
  --fields-app-preview-sets: list<string> # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersionLocalizations/{id}/appPreviewSets"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[previewType]", var: filter_preview_type, style: csv}, {name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: "fields[appPreviews]", var: fields_app_previews, style: csv}, {name: "fields[appPreviewSets]", var: fields_app_preview_sets, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_preview_type: $filter_preview_type, fields_app_store_version_localizations: $fields_app_store_version_localizations, fields_app_previews: $fields_app_previews, fields_app_preview_sets: $fields_app_preview_sets, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appStoreVersionLocalizations-appScreenshotSets-get_to_many_related
export def "app-store-version-localizations-app-screenshot-sets-get-to-many-related" [
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
  --filter-screenshot-display-type: list<string> # filter by attribute 'screenshotDisplayType'
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-app-screenshot-sets: list<string> # the fields to include for returned resources of type appScreenshotSets
  --fields-app-screenshots: list<string> # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersionLocalizations/{id}/appScreenshotSets"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[screenshotDisplayType]", var: filter_screenshot_display_type, style: csv}, {name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: "fields[appScreenshotSets]", var: fields_app_screenshot_sets, style: csv}, {name: "fields[appScreenshots]", var: fields_app_screenshots, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_screenshot_display_type: $filter_screenshot_display_type, fields_app_store_version_localizations: $fields_app_store_version_localizations, fields_app_screenshot_sets: $fields_app_screenshot_sets, fields_app_screenshots: $fields_app_screenshots, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreVersionPhasedReleases
#
# Returns: record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appStoreVersionPhasedReleases-create_instance
export def "app-store-version-phased-releases-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appStoreVersionPhasedReleases"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreVersionPhasedReleases"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appStoreVersionPhasedReleases/{id}
#
# operationId: appStoreVersionPhasedReleases-delete_instance
export def "app-store-version-phased-releases-delete-instance" [
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
    path: "/v1/appStoreVersionPhasedReleases/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreVersionPhasedReleases/{id}
#
# Returns: record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appStoreVersionPhasedReleases-update_instance
export def "app-store-version-phased-releases-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "appStoreVersionPhasedReleases"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appStoreVersionPhasedReleases/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreVersionSubmissions
#
# Returns: record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: appStoreVersionSubmissions-create_instance
export def "app-store-version-submissions-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "appStoreVersionSubmissions"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreVersionSubmissions"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appStoreVersionSubmissions/{id}
#
# operationId: appStoreVersionSubmissions-delete_instance
export def "app-store-version-submissions-delete-instance" [
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
    path: "/v1/appStoreVersionSubmissions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/appStoreVersions
#
# Returns: record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersions-create_instance
export def "app-store-versions-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreVersions"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/appStoreVersions"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/appStoreVersions/{id}
#
# operationId: appStoreVersions-delete_instance
export def "app-store-versions-delete-instance" [
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
    path: "/v1/appStoreVersions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}
#
# Returns: record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersions-get_instance
@deprecated --flag fields-age-rating-declarations
export def "app-store-versions-get-instance" [
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
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-idfa-declarations: list<string> # the fields to include for returned resources of type idfaDeclarations
  --fields-routing-app-coverages: list<string> # the fields to include for returned resources of type routingAppCoverages
  --fields-app-store-version-phased-releases: list<string> # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
  --fields-app-store-review-details: list<string> # the fields to include for returned resources of type appStoreReviewDetails
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-app-store-version-submissions: list<string> # the fields to include for returned resources of type appStoreVersionSubmissions
  --limit-app-store-version-localizations: int # maximum number of related appStoreVersionLocalizations returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: "fields[idfaDeclarations]", var: fields_idfa_declarations, style: csv}, {name: "fields[routingAppCoverages]", var: fields_routing_app_coverages, style: csv}, {name: "fields[appStoreVersionPhasedReleases]", var: fields_app_store_version_phased_releases, style: csv}, {name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}, {name: "fields[appStoreReviewDetails]", var: fields_app_store_review_details, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[appStoreVersionSubmissions]", var: fields_app_store_version_submissions, style: csv}, {name: "limit[appStoreVersionLocalizations]", var: limit_app_store_version_localizations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_versions: $fields_app_store_versions, include: $include, fields_app_store_version_localizations: $fields_app_store_version_localizations, fields_idfa_declarations: $fields_idfa_declarations, fields_routing_app_coverages: $fields_routing_app_coverages, fields_app_store_version_phased_releases: $fields_app_store_version_phased_releases, fields_age_rating_declarations: $fields_age_rating_declarations, fields_app_store_review_details: $fields_app_store_review_details, fields_builds: $fields_builds, fields_app_store_version_submissions: $fields_app_store_version_submissions, limit_app_store_version_localizations: $limit_app_store_version_localizations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreVersions/{id}
#
# Returns: record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersions-update_instance
export def "app-store-versions-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "appStoreVersions"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/appStoreVersions/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/ageRatingDeclaration
#
# DEPRECATED
# Returns: record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appStoreVersions-ageRatingDeclaration-get_to_one_related
@deprecated
@deprecated --flag fields-age-rating-declarations
export def "app-store-versions-age-rating-declaration-get-to-one-related" [
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
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/ageRatingDeclaration"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_age_rating_declarations: $fields_age_rating_declarations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/appStoreReviewDetail
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: appStoreVersions-appStoreReviewDetail-get_to_one_related
export def "app-store-versions-app-store-review-detail-get-to-one-related" [
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
  --fields-app-store-review-details: list<string> # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-app-store-review-attachments: list<string> # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/appStoreReviewDetail"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreReviewDetails]", var: fields_app_store_review_details, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[appStoreReviewAttachments]", var: fields_app_store_review_attachments, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_review_details: $fields_app_store_review_details, fields_app_store_versions: $fields_app_store_versions, fields_app_store_review_attachments: $fields_app_store_review_attachments, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: appStoreVersions-appStoreVersionLocalizations-get_to_many_related
export def "app-store-versions-app-store-version-localizations-get-to-many-related" [
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
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/appStoreVersionLocalizations"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_version_localizations: $fields_app_store_version_localizations, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/appStoreVersionPhasedRelease
#
# Returns: record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: appStoreVersions-appStoreVersionPhasedRelease-get_to_one_related
export def "app-store-versions-app-store-version-phased-release-get-to-one-related" [
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
  --fields-app-store-version-phased-releases: list<string> # the fields to include for returned resources of type appStoreVersionPhasedReleases
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/appStoreVersionPhasedRelease"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersionPhasedReleases]", var: fields_app_store_version_phased_releases, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_version_phased_releases: $fields_app_store_version_phased_releases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/appStoreVersionSubmission
#
# Returns: record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: appStoreVersions-appStoreVersionSubmission-get_to_one_related
export def "app-store-versions-app-store-version-submission-get-to-one-related" [
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
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-app-store-version-submissions: list<string> # the fields to include for returned resources of type appStoreVersionSubmissions
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/appStoreVersionSubmission"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[appStoreVersionSubmissions]", var: fields_app_store_version_submissions, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_versions: $fields_app_store_versions, fields_app_store_version_submissions: $fields_app_store_version_submissions, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/build
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: appStoreVersions-build-get_to_one_related
export def "app-store-versions-build-get-to-one-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/build"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/idfaDeclaration
#
# Returns: record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: appStoreVersions-idfaDeclaration-get_to_one_related
export def "app-store-versions-idfa-declaration-get-to-one-related" [
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
  --fields-idfa-declarations: list<string> # the fields to include for returned resources of type idfaDeclarations
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/idfaDeclaration"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[idfaDeclarations]", var: fields_idfa_declarations, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_idfa_declarations: $fields_idfa_declarations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/relationships/build
#
# Returns: record<data: record<id: string, type: string>, links: record<self: string>>
# operationId: appStoreVersions-build-get_to_one_relationship
export def "app-store-versions-build-get-to-one-relationship" [
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
    path: "/v1/appStoreVersions/{id}/relationships/build"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/appStoreVersions/{id}/relationships/build
#
# operationId: appStoreVersions-build-update_to_one_relationship
export def "app-store-versions-build-update-to-one-relationship" [
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
  data: record # shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/appStoreVersions/{id}/relationships/build"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/appStoreVersions/{id}/routingAppCoverage
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: appStoreVersions-routingAppCoverage-get_to_one_related
export def "app-store-versions-routing-app-coverage-get-to-one-related" [
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
  --fields-routing-app-coverages: list<string> # the fields to include for returned resources of type routingAppCoverages
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/appStoreVersions/{id}/routingAppCoverage"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[routingAppCoverages]", var: fields_routing_app_coverages, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_routing_app_coverages: $fields_routing_app_coverages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-get_collection
export def "apps-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app-store-versions-app-store-state: list<string> # filter by attribute 'appStoreVersions.appStoreState'
  --filter-app-store-versions-platform: list<string> # filter by attribute 'appStoreVersions.platform'
  --filter-bundle-id: list<string> # filter by attribute 'bundleId'
  --filter-name: list<string> # filter by attribute 'name'
  --filter-sku: list<string> # filter by attribute 'sku'
  --filter-app-store-versions: list<string> # filter by id(s) of related 'appStoreVersions'
  --filter-id: list<string> # filter by id(s)
  --exists-game-center-enabled-versions: list<string> # filter by existence or non-existence of related 'gameCenterEnabledVersions'
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --fields-perf-power-metrics: list<string> # the fields to include for returned resources of type perfPowerMetrics
  --fields-app-infos: list<string> # the fields to include for returned resources of type appInfos
  --fields-app-pre-orders: list<string> # the fields to include for returned resources of type appPreOrders
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --fields-app-prices: list<string> # the fields to include for returned resources of type appPrices
  --fields-in-app-purchases: list<string> # the fields to include for returned resources of type inAppPurchases
  --fields-beta-app-review-details: list<string> # the fields to include for returned resources of type betaAppReviewDetails
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --fields-game-center-enabled-versions: list<string> # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-beta-app-localizations: list<string> # the fields to include for returned resources of type betaAppLocalizations
  --fields-beta-license-agreements: list<string> # the fields to include for returned resources of type betaLicenseAgreements
  --fields-end-user-license-agreements: list<string> # the fields to include for returned resources of type endUserLicenseAgreements
  --limit-app-infos: int # maximum number of related appInfos returned (when they are included)
  --limit-app-store-versions: int # maximum number of related appStoreVersions returned (when they are included)
  --limit-available-territories: int # maximum number of related availableTerritories returned (when they are included)
  --limit-beta-app-localizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
  --limit-game-center-enabled-versions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limit-in-app-purchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limit-pre-release-versions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limit-prices: int # maximum number of related prices returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps"
    query: [{name: "filter[appStoreVersions.appStoreState]", var: filter_app_store_versions_app_store_state, style: csv}, {name: "filter[appStoreVersions.platform]", var: filter_app_store_versions_platform, style: csv}, {name: "filter[bundleId]", var: filter_bundle_id, style: csv}, {name: "filter[name]", var: filter_name, style: csv}, {name: "filter[sku]", var: filter_sku, style: csv}, {name: "filter[appStoreVersions]", var: filter_app_store_versions, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: "exists[gameCenterEnabledVersions]", var: exists_game_center_enabled_versions, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: "fields[perfPowerMetrics]", var: fields_perf_power_metrics, style: csv}, {name: "fields[appInfos]", var: fields_app_infos, style: csv}, {name: "fields[appPreOrders]", var: fields_app_pre_orders, style: csv}, {name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: "fields[appPrices]", var: fields_app_prices, style: csv}, {name: "fields[inAppPurchases]", var: fields_in_app_purchases, style: csv}, {name: "fields[betaAppReviewDetails]", var: fields_beta_app_review_details, style: csv}, {name: "fields[territories]", var: fields_territories, style: csv}, {name: "fields[gameCenterEnabledVersions]", var: fields_game_center_enabled_versions, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[betaAppLocalizations]", var: fields_beta_app_localizations, style: csv}, {name: "fields[betaLicenseAgreements]", var: fields_beta_license_agreements, style: csv}, {name: "fields[endUserLicenseAgreements]", var: fields_end_user_license_agreements, style: csv}, {name: "limit[appInfos]", var: limit_app_infos}, {name: "limit[appStoreVersions]", var: limit_app_store_versions}, {name: "limit[availableTerritories]", var: limit_available_territories}, {name: "limit[betaAppLocalizations]", var: limit_beta_app_localizations}, {name: "limit[betaGroups]", var: limit_beta_groups}, {name: "limit[builds]", var: limit_builds}, {name: "limit[gameCenterEnabledVersions]", var: limit_game_center_enabled_versions}, {name: "limit[inAppPurchases]", var: limit_in_app_purchases}, {name: "limit[preReleaseVersions]", var: limit_pre_release_versions}, {name: "limit[prices]", var: limit_prices}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_app_store_versions_app_store_state: $filter_app_store_versions_app_store_state, filter_app_store_versions_platform: $filter_app_store_versions_platform, filter_bundle_id: $filter_bundle_id, filter_name: $filter_name, filter_sku: $filter_sku, filter_app_store_versions: $filter_app_store_versions, filter_id: $filter_id, exists_game_center_enabled_versions: $exists_game_center_enabled_versions, sort: $sort, fields_apps: $fields_apps, limit: $limit, include: $include, fields_beta_groups: $fields_beta_groups, fields_perf_power_metrics: $fields_perf_power_metrics, fields_app_infos: $fields_app_infos, fields_app_pre_orders: $fields_app_pre_orders, fields_pre_release_versions: $fields_pre_release_versions, fields_app_prices: $fields_app_prices, fields_in_app_purchases: $fields_in_app_purchases, fields_beta_app_review_details: $fields_beta_app_review_details, fields_territories: $fields_territories, fields_game_center_enabled_versions: $fields_game_center_enabled_versions, fields_app_store_versions: $fields_app_store_versions, fields_builds: $fields_builds, fields_beta_app_localizations: $fields_beta_app_localizations, fields_beta_license_agreements: $fields_beta_license_agreements, fields_end_user_license_agreements: $fields_end_user_license_agreements, limit_app_infos: $limit_app_infos, limit_app_store_versions: $limit_app_store_versions, limit_available_territories: $limit_available_territories, limit_beta_app_localizations: $limit_beta_app_localizations, limit_beta_groups: $limit_beta_groups, limit_builds: $limit_builds, limit_game_center_enabled_versions: $limit_game_center_enabled_versions, limit_in_app_purchases: $limit_in_app_purchases, limit_pre_release_versions: $limit_pre_release_versions, limit_prices: $limit_prices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: apps-get_instance
export def "apps-get-instance" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --include: list<string> # comma-separated list of relationships to include
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --fields-perf-power-metrics: list<string> # the fields to include for returned resources of type perfPowerMetrics
  --fields-app-infos: list<string> # the fields to include for returned resources of type appInfos
  --fields-app-pre-orders: list<string> # the fields to include for returned resources of type appPreOrders
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --fields-app-prices: list<string> # the fields to include for returned resources of type appPrices
  --fields-in-app-purchases: list<string> # the fields to include for returned resources of type inAppPurchases
  --fields-beta-app-review-details: list<string> # the fields to include for returned resources of type betaAppReviewDetails
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --fields-game-center-enabled-versions: list<string> # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-beta-app-localizations: list<string> # the fields to include for returned resources of type betaAppLocalizations
  --fields-beta-license-agreements: list<string> # the fields to include for returned resources of type betaLicenseAgreements
  --fields-end-user-license-agreements: list<string> # the fields to include for returned resources of type endUserLicenseAgreements
  --limit-app-infos: int # maximum number of related appInfos returned (when they are included)
  --limit-app-store-versions: int # maximum number of related appStoreVersions returned (when they are included)
  --limit-available-territories: int # maximum number of related availableTerritories returned (when they are included)
  --limit-beta-app-localizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
  --limit-game-center-enabled-versions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limit-in-app-purchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limit-pre-release-versions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limit-prices: int # maximum number of related prices returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}, {name: include, var: include, style: csv}, {name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: "fields[perfPowerMetrics]", var: fields_perf_power_metrics, style: csv}, {name: "fields[appInfos]", var: fields_app_infos, style: csv}, {name: "fields[appPreOrders]", var: fields_app_pre_orders, style: csv}, {name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: "fields[appPrices]", var: fields_app_prices, style: csv}, {name: "fields[inAppPurchases]", var: fields_in_app_purchases, style: csv}, {name: "fields[betaAppReviewDetails]", var: fields_beta_app_review_details, style: csv}, {name: "fields[territories]", var: fields_territories, style: csv}, {name: "fields[gameCenterEnabledVersions]", var: fields_game_center_enabled_versions, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[betaAppLocalizations]", var: fields_beta_app_localizations, style: csv}, {name: "fields[betaLicenseAgreements]", var: fields_beta_license_agreements, style: csv}, {name: "fields[endUserLicenseAgreements]", var: fields_end_user_license_agreements, style: csv}, {name: "limit[appInfos]", var: limit_app_infos}, {name: "limit[appStoreVersions]", var: limit_app_store_versions}, {name: "limit[availableTerritories]", var: limit_available_territories}, {name: "limit[betaAppLocalizations]", var: limit_beta_app_localizations}, {name: "limit[betaGroups]", var: limit_beta_groups}, {name: "limit[builds]", var: limit_builds}, {name: "limit[gameCenterEnabledVersions]", var: limit_game_center_enabled_versions}, {name: "limit[inAppPurchases]", var: limit_in_app_purchases}, {name: "limit[preReleaseVersions]", var: limit_pre_release_versions}, {name: "limit[prices]", var: limit_prices}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps, include: $include, fields_beta_groups: $fields_beta_groups, fields_perf_power_metrics: $fields_perf_power_metrics, fields_app_infos: $fields_app_infos, fields_app_pre_orders: $fields_app_pre_orders, fields_pre_release_versions: $fields_pre_release_versions, fields_app_prices: $fields_app_prices, fields_in_app_purchases: $fields_in_app_purchases, fields_beta_app_review_details: $fields_beta_app_review_details, fields_territories: $fields_territories, fields_game_center_enabled_versions: $fields_game_center_enabled_versions, fields_app_store_versions: $fields_app_store_versions, fields_builds: $fields_builds, fields_beta_app_localizations: $fields_beta_app_localizations, fields_beta_license_agreements: $fields_beta_license_agreements, fields_end_user_license_agreements: $fields_end_user_license_agreements, limit_app_infos: $limit_app_infos, limit_app_store_versions: $limit_app_store_versions, limit_available_territories: $limit_available_territories, limit_beta_app_localizations: $limit_beta_app_localizations, limit_beta_groups: $limit_beta_groups, limit_builds: $limit_builds, limit_game_center_enabled_versions: $limit_game_center_enabled_versions, limit_in_app_purchases: $limit_in_app_purchases, limit_pre_release_versions: $limit_pre_release_versions, limit_prices: $limit_prices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/apps/{id}
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: apps-update_instance
export def "apps-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "apps"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/apps/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/appInfos
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-appInfos-get_to_many_related
export def "apps-app-infos-get-to-many-related" [
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
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-infos: list<string> # the fields to include for returned resources of type appInfos
  --fields-app-categories: list<string> # the fields to include for returned resources of type appCategories
  --fields-app-info-localizations: list<string> # the fields to include for returned resources of type appInfoLocalizations
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/appInfos"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}, {name: "fields[appInfos]", var: fields_app_infos, style: csv}, {name: "fields[appCategories]", var: fields_app_categories, style: csv}, {name: "fields[appInfoLocalizations]", var: fields_app_info_localizations, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_age_rating_declarations: $fields_age_rating_declarations, fields_app_infos: $fields_app_infos, fields_app_categories: $fields_app_categories, fields_app_info_localizations: $fields_app_info_localizations, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/appStoreVersions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-appStoreVersions-get_to_many_related
export def "apps-app-store-versions-get-to-many-related" [
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
  --filter-app-store-state: list<string> # filter by attribute 'appStoreState'
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-version-string: list<string> # filter by attribute 'versionString'
  --filter-id: list<string> # filter by id(s)
  --fields-idfa-declarations: list<string> # the fields to include for returned resources of type idfaDeclarations
  --fields-app-store-version-localizations: list<string> # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-routing-app-coverages: list<string> # the fields to include for returned resources of type routingAppCoverages
  --fields-app-store-version-phased-releases: list<string> # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fields-age-rating-declarations: list<string> # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-store-review-details: list<string> # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-app-store-version-submissions: list<string> # the fields to include for returned resources of type appStoreVersionSubmissions
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/appStoreVersions"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[appStoreState]", var: filter_app_store_state, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[versionString]", var: filter_version_string, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: "fields[idfaDeclarations]", var: fields_idfa_declarations, style: csv}, {name: "fields[appStoreVersionLocalizations]", var: fields_app_store_version_localizations, style: csv}, {name: "fields[routingAppCoverages]", var: fields_routing_app_coverages, style: csv}, {name: "fields[appStoreVersionPhasedReleases]", var: fields_app_store_version_phased_releases, style: csv}, {name: "fields[ageRatingDeclarations]", var: fields_age_rating_declarations, style: csv}, {name: "fields[appStoreReviewDetails]", var: fields_app_store_review_details, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[appStoreVersionSubmissions]", var: fields_app_store_version_submissions, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_app_store_state: $filter_app_store_state, filter_platform: $filter_platform, filter_version_string: $filter_version_string, filter_id: $filter_id, fields_idfa_declarations: $fields_idfa_declarations, fields_app_store_version_localizations: $fields_app_store_version_localizations, fields_routing_app_coverages: $fields_routing_app_coverages, fields_app_store_version_phased_releases: $fields_app_store_version_phased_releases, fields_age_rating_declarations: $fields_age_rating_declarations, fields_app_store_review_details: $fields_app_store_review_details, fields_app_store_versions: $fields_app_store_versions, fields_builds: $fields_builds, fields_app_store_version_submissions: $fields_app_store_version_submissions, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/availableTerritories
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-availableTerritories-get_to_many_related
export def "apps-available-territories-get-to-many-related" [
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
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/availableTerritories"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[territories]", var: fields_territories, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_territories: $fields_territories, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/betaAppLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-betaAppLocalizations-get_to_many_related
export def "apps-beta-app-localizations-get-to-many-related" [
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
  --fields-beta-app-localizations: list<string> # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/betaAppLocalizations"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppLocalizations]", var: fields_beta_app_localizations, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_localizations: $fields_beta_app_localizations, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/betaAppReviewDetail
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: apps-betaAppReviewDetail-get_to_one_related
export def "apps-beta-app-review-detail-get-to-one-related" [
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
  --fields-beta-app-review-details: list<string> # the fields to include for returned resources of type betaAppReviewDetails
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/betaAppReviewDetail"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppReviewDetails]", var: fields_beta_app_review_details, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_review_details: $fields_beta_app_review_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/betaGroups
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-betaGroups-get_to_many_related
export def "apps-beta-groups-get-to-many-related" [
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
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/betaGroups"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_groups: $fields_beta_groups, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/betaLicenseAgreement
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: apps-betaLicenseAgreement-get_to_one_related
export def "apps-beta-license-agreement-get-to-one-related" [
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
  --fields-beta-license-agreements: list<string> # the fields to include for returned resources of type betaLicenseAgreements
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/betaLicenseAgreement"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaLicenseAgreements]", var: fields_beta_license_agreements, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_license_agreements: $fields_beta_license_agreements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/builds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-builds-get_to_many_related
export def "apps-builds-get-to-many-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/builds"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/endUserLicenseAgreement
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>
# operationId: apps-endUserLicenseAgreement-get_to_one_related
export def "apps-end-user-license-agreement-get-to-one-related" [
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
  --fields-end-user-license-agreements: list<string> # the fields to include for returned resources of type endUserLicenseAgreements
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/endUserLicenseAgreement"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[endUserLicenseAgreements]", var: fields_end_user_license_agreements, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_end_user_license_agreements: $fields_end_user_license_agreements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/gameCenterEnabledVersions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-gameCenterEnabledVersions-get_to_many_related
export def "apps-game-center-enabled-versions-get-to-many-related" [
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
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-version-string: list<string> # filter by attribute 'versionString'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-game-center-enabled-versions: list<string> # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/gameCenterEnabledVersions"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[versionString]", var: filter_version_string, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[gameCenterEnabledVersions]", var: fields_game_center_enabled_versions, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_platform: $filter_platform, filter_version_string: $filter_version_string, filter_id: $filter_id, sort: $sort, fields_game_center_enabled_versions: $fields_game_center_enabled_versions, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/inAppPurchases
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-inAppPurchases-get_to_many_related
export def "apps-in-app-purchases-get-to-many-related" [
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
  --filter-in-app-purchase-type: list<string> # filter by attribute 'inAppPurchaseType'
  --filter-can-be-submitted: list<string> # filter by canBeSubmitted
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-in-app-purchases: list<string> # the fields to include for returned resources of type inAppPurchases
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/inAppPurchases"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[inAppPurchaseType]", var: filter_in_app_purchase_type, style: csv}, {name: "filter[canBeSubmitted]", var: filter_can_be_submitted, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[inAppPurchases]", var: fields_in_app_purchases, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_in_app_purchase_type: $filter_in_app_purchase_type, filter_can_be_submitted: $filter_can_be_submitted, sort: $sort, fields_in_app_purchases: $fields_in_app_purchases, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/perfPowerMetrics
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-perfPowerMetrics-get_to_many_related
export def "apps-perf-power-metrics-get-to-many-related" [
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
  --filter-device-type: list<string> # filter by attribute 'deviceType'
  --filter-metric-type: list<string> # filter by attribute 'metricType'
  --filter-platform: list<string> # filter by attribute 'platform'
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/perfPowerMetrics"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[deviceType]", var: filter_device_type, style: csv}, {name: "filter[metricType]", var: filter_metric_type, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_device_type: $filter_device_type, filter_metric_type: $filter_metric_type, filter_platform: $filter_platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/preOrder
#
# Returns: record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>>
# operationId: apps-preOrder-get_to_one_related
export def "apps-pre-order-get-to-one-related" [
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
  --fields-app-pre-orders: list<string> # the fields to include for returned resources of type appPreOrders
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/preOrder"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPreOrders]", var: fields_app_pre_orders, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_pre_orders: $fields_app_pre_orders
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/preReleaseVersions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-preReleaseVersions-get_to_many_related
export def "apps-pre-release-versions-get-to-many-related" [
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
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/preReleaseVersions"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_pre_release_versions: $fields_pre_release_versions, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/apps/{id}/prices
#
# Returns: record<data: table<id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: apps-prices-get_to_many_related
export def "apps-prices-get-to-many-related" [
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
  --fields-app-prices: list<string> # the fields to include for returned resources of type appPrices
  --fields-app-price-tiers: list<string> # the fields to include for returned resources of type appPriceTiers
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/apps/{id}/prices"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appPrices]", var: fields_app_prices, style: csv}, {name: "fields[appPriceTiers]", var: fields_app_price_tiers, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_prices: $fields_app_prices, fields_app_price_tiers: $fields_app_price_tiers, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/apps/{id}/relationships/betaTesters
#
# operationId: apps-betaTesters-delete_to_many_relationship
export def "apps-beta-testers-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/apps/{id}/relationships/betaTesters"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaAppLocalizations-get_collection
export def "beta-app-localizations-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-locale: list<string> # filter by attribute 'locale'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --fields-beta-app-localizations: list<string> # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppLocalizations"
    query: [{name: "filter[locale]", var: filter_locale, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "fields[betaAppLocalizations]", var: fields_beta_app_localizations, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_locale: $filter_locale, filter_app: $filter_app, fields_beta_app_localizations: $fields_beta_app_localizations, limit: $limit, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaAppLocalizations
#
# Returns: record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppLocalizations-create_instance
export def "beta-app-localizations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaAppLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaAppLocalizations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaAppLocalizations/{id}
#
# operationId: betaAppLocalizations-delete_instance
export def "beta-app-localizations-delete-instance" [
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
    path: "/v1/betaAppLocalizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppLocalizations/{id}
#
# Returns: record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppLocalizations-get_instance
export def "beta-app-localizations-get-instance" [
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
  --fields-beta-app-localizations: list<string> # the fields to include for returned resources of type betaAppLocalizations
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppLocalizations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppLocalizations]", var: fields_beta_app_localizations, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_localizations: $fields_beta_app_localizations, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/betaAppLocalizations/{id}
#
# Returns: record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppLocalizations-update_instance
export def "beta-app-localizations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "betaAppLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/betaAppLocalizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppLocalizations/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaAppLocalizations-app-get_to_one_related
export def "beta-app-localizations-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppLocalizations/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewDetails
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaAppReviewDetails-get_collection
export def "beta-app-review-details-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app: list<string> # filter by id(s) of related 'app' (required)
  --fields-beta-app-review-details: list<string> # the fields to include for returned resources of type betaAppReviewDetails
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewDetails"
    query: [{name: "filter[app]", var: filter_app, style: csv, required: true}, {name: "fields[betaAppReviewDetails]", var: fields_beta_app_review_details, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_app: $filter_app, fields_beta_app_review_details: $fields_beta_app_review_details, limit: $limit, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewDetails/{id}
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppReviewDetails-get_instance
export def "beta-app-review-details-get-instance" [
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
  --fields-beta-app-review-details: list<string> # the fields to include for returned resources of type betaAppReviewDetails
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewDetails/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppReviewDetails]", var: fields_beta_app_review_details, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_review_details: $fields_beta_app_review_details, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/betaAppReviewDetails/{id}
#
# Returns: record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppReviewDetails-update_instance
export def "beta-app-review-details-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "betaAppReviewDetails"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/betaAppReviewDetails/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewDetails/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaAppReviewDetails-app-get_to_one_related
export def "beta-app-review-details-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewDetails/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewSubmissions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaAppReviewSubmissions-get_collection
export def "beta-app-review-submissions-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-beta-review-state: list<string> # filter by attribute 'betaReviewState'
  --filter-build: list<string> # filter by id(s) of related 'build' (required)
  --fields-beta-app-review-submissions: list<string> # the fields to include for returned resources of type betaAppReviewSubmissions
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewSubmissions"
    query: [{name: "filter[betaReviewState]", var: filter_beta_review_state, style: csv}, {name: "filter[build]", var: filter_build, style: csv, required: true}, {name: "fields[betaAppReviewSubmissions]", var: fields_beta_app_review_submissions, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_beta_review_state: $filter_beta_review_state, filter_build: $filter_build, fields_beta_app_review_submissions: $fields_beta_app_review_submissions, limit: $limit, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaAppReviewSubmissions
#
# Returns: record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppReviewSubmissions-create_instance
export def "beta-app-review-submissions-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "betaAppReviewSubmissions"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaAppReviewSubmissions"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewSubmissions/{id}
#
# Returns: record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaAppReviewSubmissions-get_instance
export def "beta-app-review-submissions-get-instance" [
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
  --fields-beta-app-review-submissions: list<string> # the fields to include for returned resources of type betaAppReviewSubmissions
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewSubmissions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppReviewSubmissions]", var: fields_beta_app_review_submissions, style: csv}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_review_submissions: $fields_beta_app_review_submissions, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaAppReviewSubmissions/{id}/build
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaAppReviewSubmissions-build-get_to_one_related
export def "beta-app-review-submissions-build-get-to-one-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaAppReviewSubmissions/{id}/build"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaBuildLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaBuildLocalizations-get_collection
export def "beta-build-localizations-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-locale: list<string> # filter by attribute 'locale'
  --filter-build: list<string> # filter by id(s) of related 'build'
  --fields-beta-build-localizations: list<string> # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaBuildLocalizations"
    query: [{name: "filter[locale]", var: filter_locale, style: csv}, {name: "filter[build]", var: filter_build, style: csv}, {name: "fields[betaBuildLocalizations]", var: fields_beta_build_localizations, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_locale: $filter_locale, filter_build: $filter_build, fields_beta_build_localizations: $fields_beta_build_localizations, limit: $limit, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaBuildLocalizations
#
# Returns: record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaBuildLocalizations-create_instance
export def "beta-build-localizations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaBuildLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaBuildLocalizations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaBuildLocalizations/{id}
#
# operationId: betaBuildLocalizations-delete_instance
export def "beta-build-localizations-delete-instance" [
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
    path: "/v1/betaBuildLocalizations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaBuildLocalizations/{id}
#
# Returns: record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaBuildLocalizations-get_instance
export def "beta-build-localizations-get-instance" [
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
  --fields-beta-build-localizations: list<string> # the fields to include for returned resources of type betaBuildLocalizations
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaBuildLocalizations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaBuildLocalizations]", var: fields_beta_build_localizations, style: csv}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_build_localizations: $fields_beta_build_localizations, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/betaBuildLocalizations/{id}
#
# Returns: record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaBuildLocalizations-update_instance
export def "beta-build-localizations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "betaBuildLocalizations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/betaBuildLocalizations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaBuildLocalizations/{id}/build
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaBuildLocalizations-build-get_to_one_related
export def "beta-build-localizations-build-get-to-one-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaBuildLocalizations/{id}/build"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaGroups-get_collection
export def "beta-groups-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-is-internal-group: list<string> # filter by attribute 'isInternalGroup'
  --filter-name: list<string> # filter by attribute 'name'
  --filter-public-link: list<string> # filter by attribute 'publicLink'
  --filter-public-link-enabled: list<string> # filter by attribute 'publicLinkEnabled'
  --filter-public-link-limit-enabled: list<string> # filter by attribute 'publicLinkLimitEnabled'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --filter-builds: list<string> # filter by id(s) of related 'builds'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-beta-testers: int # maximum number of related betaTesters returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups"
    query: [{name: "filter[isInternalGroup]", var: filter_is_internal_group, style: csv}, {name: "filter[name]", var: filter_name, style: csv}, {name: "filter[publicLink]", var: filter_public_link, style: csv}, {name: "filter[publicLinkEnabled]", var: filter_public_link_enabled, style: csv}, {name: "filter[publicLinkLimitEnabled]", var: filter_public_link_limit_enabled, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "filter[builds]", var: filter_builds, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[betaTesters]", var: limit_beta_testers}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_is_internal_group: $filter_is_internal_group, filter_name: $filter_name, filter_public_link: $filter_public_link, filter_public_link_enabled: $filter_public_link_enabled, filter_public_link_limit_enabled: $filter_public_link_limit_enabled, filter_app: $filter_app, filter_builds: $filter_builds, filter_id: $filter_id, sort: $sort, fields_beta_groups: $fields_beta_groups, limit: $limit, include: $include, fields_builds: $fields_builds, fields_beta_testers: $fields_beta_testers, fields_apps: $fields_apps, limit_beta_testers: $limit_beta_testers, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaGroups
#
# Returns: record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaGroups-create_instance
export def "beta-groups-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaGroups"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaGroups"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaGroups/{id}
#
# operationId: betaGroups-delete_instance
export def "beta-groups-delete-instance" [
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
    path: "/v1/betaGroups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}
#
# Returns: record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaGroups-get_instance
export def "beta-groups-get-instance" [
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
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-beta-testers: int # maximum number of related betaTesters returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[betaTesters]", var: limit_beta_testers}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_groups: $fields_beta_groups, include: $include, fields_builds: $fields_builds, fields_beta_testers: $fields_beta_testers, fields_apps: $fields_apps, limit_beta_testers: $limit_beta_testers, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/betaGroups/{id}
#
# Returns: record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaGroups-update_instance
export def "beta-groups-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "betaGroups"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/betaGroups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaGroups-app-get_to_one_related
export def "beta-groups-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}/betaTesters
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaGroups-betaTesters-get_to_many_related
export def "beta-groups-beta-testers-get-to-many-related" [
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
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}/betaTesters"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_testers: $fields_beta_testers, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}/builds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaGroups-builds-get_to_many_related
export def "beta-groups-builds-get-to-many-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}/builds"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaGroups/{id}/relationships/betaTesters
#
# operationId: betaGroups-betaTesters-delete_to_many_relationship
export def "beta-groups-beta-testers-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/betaGroups/{id}/relationships/betaTesters"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}/relationships/betaTesters
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaGroups-betaTesters-get_to_many_relationship
export def "beta-groups-beta-testers-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}/relationships/betaTesters"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaGroups/{id}/relationships/betaTesters
#
# operationId: betaGroups-betaTesters-create_to_many_relationship
export def "beta-groups-beta-testers-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/betaGroups/{id}/relationships/betaTesters"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaGroups/{id}/relationships/builds
#
# operationId: betaGroups-builds-delete_to_many_relationship
export def "beta-groups-builds-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/betaGroups/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaGroups/{id}/relationships/builds
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaGroups-builds-get_to_many_relationship
export def "beta-groups-builds-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaGroups/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaGroups/{id}/relationships/builds
#
# operationId: betaGroups-builds-create_to_many_relationship
export def "beta-groups-builds-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/betaGroups/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaLicenseAgreements
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaLicenseAgreements-get_collection
export def "beta-license-agreements-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app: list<string> # filter by id(s) of related 'app'
  --fields-beta-license-agreements: list<string> # the fields to include for returned resources of type betaLicenseAgreements
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaLicenseAgreements"
    query: [{name: "filter[app]", var: filter_app, style: csv}, {name: "fields[betaLicenseAgreements]", var: fields_beta_license_agreements, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_app: $filter_app, fields_beta_license_agreements: $fields_beta_license_agreements, limit: $limit, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaLicenseAgreements/{id}
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaLicenseAgreements-get_instance
export def "beta-license-agreements-get-instance" [
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
  --fields-beta-license-agreements: list<string> # the fields to include for returned resources of type betaLicenseAgreements
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaLicenseAgreements/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaLicenseAgreements]", var: fields_beta_license_agreements, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_license_agreements: $fields_beta_license_agreements, include: $include, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/betaLicenseAgreements/{id}
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: betaLicenseAgreements-update_instance
export def "beta-license-agreements-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "betaLicenseAgreements"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/betaLicenseAgreements/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaLicenseAgreements/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaLicenseAgreements-app-get_to_one_related
export def "beta-license-agreements-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaLicenseAgreements/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaTesterInvitations
#
# Returns: record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: betaTesterInvitations-create_instance
export def "beta-tester-invitations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "betaTesterInvitations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaTesterInvitations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-get_collection
export def "beta-testers-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-email: list<string> # filter by attribute 'email'
  --filter-first-name: list<string> # filter by attribute 'firstName'
  --filter-invite-type: list<string> # filter by attribute 'inviteType'
  --filter-last-name: list<string> # filter by attribute 'lastName'
  --filter-apps: list<string> # filter by id(s) of related 'apps'
  --filter-beta-groups: list<string> # filter by id(s) of related 'betaGroups'
  --filter-builds: list<string> # filter by id(s) of related 'builds'
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-apps: int # maximum number of related apps returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters"
    query: [{name: "filter[email]", var: filter_email, style: csv}, {name: "filter[firstName]", var: filter_first_name, style: csv}, {name: "filter[inviteType]", var: filter_invite_type, style: csv}, {name: "filter[lastName]", var: filter_last_name, style: csv}, {name: "filter[apps]", var: filter_apps, style: csv}, {name: "filter[betaGroups]", var: filter_beta_groups, style: csv}, {name: "filter[builds]", var: filter_builds, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[apps]", var: limit_apps}, {name: "limit[betaGroups]", var: limit_beta_groups}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_email: $filter_email, filter_first_name: $filter_first_name, filter_invite_type: $filter_invite_type, filter_last_name: $filter_last_name, filter_apps: $filter_apps, filter_beta_groups: $filter_beta_groups, filter_builds: $filter_builds, sort: $sort, fields_beta_testers: $fields_beta_testers, limit: $limit, include: $include, fields_beta_groups: $fields_beta_groups, fields_builds: $fields_builds, fields_apps: $fields_apps, limit_apps: $limit_apps, limit_beta_groups: $limit_beta_groups, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaTesters
#
# Returns: record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaTesters-create_instance
export def "beta-testers-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships?: record, type: "betaTesters"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/betaTesters"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaTesters/{id}
#
# operationId: betaTesters-delete_instance
export def "beta-testers-delete-instance" [
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
    path: "/v1/betaTesters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}
#
# Returns: record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: betaTesters-get_instance
export def "beta-testers-get-instance" [
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
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --include: list<string> # comma-separated list of relationships to include
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-apps: int # maximum number of related apps returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: include, var: include, style: csv}, {name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[apps]", var: limit_apps}, {name: "limit[betaGroups]", var: limit_beta_groups}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_testers: $fields_beta_testers, include: $include, fields_beta_groups: $fields_beta_groups, fields_builds: $fields_builds, fields_apps: $fields_apps, limit_apps: $limit_apps, limit_beta_groups: $limit_beta_groups, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/apps
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-apps-get_to_many_related
export def "beta-testers-apps-get-to-many-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/apps"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/betaGroups
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-betaGroups-get_to_many_related
export def "beta-testers-beta-groups-get-to-many-related" [
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
  --fields-beta-groups: list<string> # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/betaGroups"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaGroups]", var: fields_beta_groups, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_groups: $fields_beta_groups, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/builds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-builds-get_to_many_related
export def "beta-testers-builds-get-to-many-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/builds"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaTesters/{id}/relationships/apps
#
# operationId: betaTesters-apps-delete_to_many_relationship
export def "beta-testers-apps-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/betaTesters/{id}/relationships/apps"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/relationships/apps
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-apps-get_to_many_relationship
export def "beta-testers-apps-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/relationships/apps"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaTesters/{id}/relationships/betaGroups
#
# operationId: betaTesters-betaGroups-delete_to_many_relationship
export def "beta-testers-beta-groups-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/betaTesters/{id}/relationships/betaGroups"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/relationships/betaGroups
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-betaGroups-get_to_many_relationship
export def "beta-testers-beta-groups-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/relationships/betaGroups"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaTesters/{id}/relationships/betaGroups
#
# operationId: betaTesters-betaGroups-create_to_many_relationship
export def "beta-testers-beta-groups-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/betaTesters/{id}/relationships/betaGroups"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/betaTesters/{id}/relationships/builds
#
# operationId: betaTesters-builds-delete_to_many_relationship
export def "beta-testers-builds-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/betaTesters/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/betaTesters/{id}/relationships/builds
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: betaTesters-builds-get_to_many_relationship
export def "beta-testers-builds-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/betaTesters/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/betaTesters/{id}/relationships/builds
#
# operationId: betaTesters-builds-create_to_many_relationship
export def "beta-testers-builds-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/betaTesters/{id}/relationships/builds"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/buildBetaDetails
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: buildBetaDetails-get_collection
export def "build-beta-details-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-build: list<string> # filter by id(s) of related 'build'
  --filter-id: list<string> # filter by id(s)
  --fields-build-beta-details: list<string> # the fields to include for returned resources of type buildBetaDetails
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/buildBetaDetails"
    query: [{name: "filter[build]", var: filter_build, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: "fields[buildBetaDetails]", var: fields_build_beta_details, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_build: $filter_build, filter_id: $filter_id, fields_build_beta_details: $fields_build_beta_details, limit: $limit, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/buildBetaDetails/{id}
#
# Returns: record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: buildBetaDetails-get_instance
export def "build-beta-details-get-instance" [
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
  --fields-build-beta-details: list<string> # the fields to include for returned resources of type buildBetaDetails
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/buildBetaDetails/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[buildBetaDetails]", var: fields_build_beta_details, style: csv}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_build_beta_details: $fields_build_beta_details, include: $include, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/buildBetaDetails/{id}
#
# Returns: record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: buildBetaDetails-update_instance
export def "build-beta-details-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "buildBetaDetails"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/buildBetaDetails/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/buildBetaDetails/{id}/build
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: buildBetaDetails-build-get_to_one_related
export def "build-beta-details-build-get-to-one-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/buildBetaDetails/{id}/build"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/buildBetaNotifications
#
# Returns: record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: buildBetaNotifications-create_instance
export def "build-beta-notifications-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "buildBetaNotifications"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/buildBetaNotifications"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-get_collection
export def "builds-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-beta-app-review-submission-beta-review-state: list<string> # filter by attribute 'betaAppReviewSubmission.betaReviewState'
  --filter-expired: list<string> # filter by attribute 'expired'
  --filter-pre-release-version-platform: list<string> # filter by attribute 'preReleaseVersion.platform'
  --filter-pre-release-version-version: list<string> # filter by attribute 'preReleaseVersion.version'
  --filter-processing-state: list<string> # filter by attribute 'processingState'
  --filter-uses-non-exempt-encryption: list<string> # filter by attribute 'usesNonExemptEncryption'
  --filter-version: list<string> # filter by attribute 'version'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --filter-app-store-version: list<string> # filter by id(s) of related 'appStoreVersion'
  --filter-beta-groups: list<string> # filter by id(s) of related 'betaGroups'
  --filter-pre-release-version: list<string> # filter by id(s) of related 'preReleaseVersion'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-encryption-declarations: list<string> # the fields to include for returned resources of type appEncryptionDeclarations
  --fields-beta-app-review-submissions: list<string> # the fields to include for returned resources of type betaAppReviewSubmissions
  --fields-build-beta-details: list<string> # the fields to include for returned resources of type buildBetaDetails
  --fields-build-icons: list<string> # the fields to include for returned resources of type buildIcons
  --fields-perf-power-metrics: list<string> # the fields to include for returned resources of type perfPowerMetrics
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-diagnostic-signatures: list<string> # the fields to include for returned resources of type diagnosticSignatures
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --fields-beta-build-localizations: list<string> # the fields to include for returned resources of type betaBuildLocalizations
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-beta-build-localizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limit-icons: int # maximum number of related icons returned (when they are included)
  --limit-individual-testers: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds"
    query: [{name: "filter[betaAppReviewSubmission.betaReviewState]", var: filter_beta_app_review_submission_beta_review_state, style: csv}, {name: "filter[expired]", var: filter_expired, style: csv}, {name: "filter[preReleaseVersion.platform]", var: filter_pre_release_version_platform, style: csv}, {name: "filter[preReleaseVersion.version]", var: filter_pre_release_version_version, style: csv}, {name: "filter[processingState]", var: filter_processing_state, style: csv}, {name: "filter[usesNonExemptEncryption]", var: filter_uses_non_exempt_encryption, style: csv}, {name: "filter[version]", var: filter_version, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "filter[appStoreVersion]", var: filter_app_store_version, style: csv}, {name: "filter[betaGroups]", var: filter_beta_groups, style: csv}, {name: "filter[preReleaseVersion]", var: filter_pre_release_version, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[appEncryptionDeclarations]", var: fields_app_encryption_declarations, style: csv}, {name: "fields[betaAppReviewSubmissions]", var: fields_beta_app_review_submissions, style: csv}, {name: "fields[buildBetaDetails]", var: fields_build_beta_details, style: csv}, {name: "fields[buildIcons]", var: fields_build_icons, style: csv}, {name: "fields[perfPowerMetrics]", var: fields_perf_power_metrics, style: csv}, {name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[diagnosticSignatures]", var: fields_diagnostic_signatures, style: csv}, {name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: "fields[betaBuildLocalizations]", var: fields_beta_build_localizations, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[betaBuildLocalizations]", var: limit_beta_build_localizations}, {name: "limit[icons]", var: limit_icons}, {name: "limit[individualTesters]", var: limit_individual_testers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_beta_app_review_submission_beta_review_state: $filter_beta_app_review_submission_beta_review_state, filter_expired: $filter_expired, filter_pre_release_version_platform: $filter_pre_release_version_platform, filter_pre_release_version_version: $filter_pre_release_version_version, filter_processing_state: $filter_processing_state, filter_uses_non_exempt_encryption: $filter_uses_non_exempt_encryption, filter_version: $filter_version, filter_app: $filter_app, filter_app_store_version: $filter_app_store_version, filter_beta_groups: $filter_beta_groups, filter_pre_release_version: $filter_pre_release_version, filter_id: $filter_id, sort: $sort, fields_builds: $fields_builds, limit: $limit, include: $include, fields_app_encryption_declarations: $fields_app_encryption_declarations, fields_beta_app_review_submissions: $fields_beta_app_review_submissions, fields_build_beta_details: $fields_build_beta_details, fields_build_icons: $fields_build_icons, fields_perf_power_metrics: $fields_perf_power_metrics, fields_pre_release_versions: $fields_pre_release_versions, fields_app_store_versions: $fields_app_store_versions, fields_diagnostic_signatures: $fields_diagnostic_signatures, fields_beta_testers: $fields_beta_testers, fields_beta_build_localizations: $fields_beta_build_localizations, fields_apps: $fields_apps, limit_beta_build_localizations: $limit_beta_build_localizations, limit_icons: $limit_icons, limit_individual_testers: $limit_individual_testers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: builds-get_instance
export def "builds-get-instance" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --include: list<string> # comma-separated list of relationships to include
  --fields-app-encryption-declarations: list<string> # the fields to include for returned resources of type appEncryptionDeclarations
  --fields-beta-app-review-submissions: list<string> # the fields to include for returned resources of type betaAppReviewSubmissions
  --fields-build-beta-details: list<string> # the fields to include for returned resources of type buildBetaDetails
  --fields-build-icons: list<string> # the fields to include for returned resources of type buildIcons
  --fields-perf-power-metrics: list<string> # the fields to include for returned resources of type perfPowerMetrics
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
  --fields-diagnostic-signatures: list<string> # the fields to include for returned resources of type diagnosticSignatures
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --fields-beta-build-localizations: list<string> # the fields to include for returned resources of type betaBuildLocalizations
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-beta-build-localizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limit-icons: int # maximum number of related icons returned (when they are included)
  --limit-individual-testers: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}, {name: include, var: include, style: csv}, {name: "fields[appEncryptionDeclarations]", var: fields_app_encryption_declarations, style: csv}, {name: "fields[betaAppReviewSubmissions]", var: fields_beta_app_review_submissions, style: csv}, {name: "fields[buildBetaDetails]", var: fields_build_beta_details, style: csv}, {name: "fields[buildIcons]", var: fields_build_icons, style: csv}, {name: "fields[perfPowerMetrics]", var: fields_perf_power_metrics, style: csv}, {name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}, {name: "fields[diagnosticSignatures]", var: fields_diagnostic_signatures, style: csv}, {name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: "fields[betaBuildLocalizations]", var: fields_beta_build_localizations, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[betaBuildLocalizations]", var: limit_beta_build_localizations}, {name: "limit[icons]", var: limit_icons}, {name: "limit[individualTesters]", var: limit_individual_testers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds, include: $include, fields_app_encryption_declarations: $fields_app_encryption_declarations, fields_beta_app_review_submissions: $fields_beta_app_review_submissions, fields_build_beta_details: $fields_build_beta_details, fields_build_icons: $fields_build_icons, fields_perf_power_metrics: $fields_perf_power_metrics, fields_pre_release_versions: $fields_pre_release_versions, fields_app_store_versions: $fields_app_store_versions, fields_diagnostic_signatures: $fields_diagnostic_signatures, fields_beta_testers: $fields_beta_testers, fields_beta_build_localizations: $fields_beta_build_localizations, fields_apps: $fields_apps, limit_beta_build_localizations: $limit_beta_build_localizations, limit_icons: $limit_icons, limit_individual_testers: $limit_individual_testers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/builds/{id}
#
# Returns: record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: builds-update_instance
export def "builds-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "builds"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/builds/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: builds-app-get_to_one_related
export def "builds-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/appEncryptionDeclaration
#
# Returns: record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: builds-appEncryptionDeclaration-get_to_one_related
export def "builds-app-encryption-declaration-get-to-one-related" [
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
  --fields-app-encryption-declarations: list<string> # the fields to include for returned resources of type appEncryptionDeclarations
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/appEncryptionDeclaration"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appEncryptionDeclarations]", var: fields_app_encryption_declarations, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_encryption_declarations: $fields_app_encryption_declarations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/appStoreVersion
#
# Returns: record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: builds-appStoreVersion-get_to_one_related
export def "builds-app-store-version-get-to-one-related" [
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
  --fields-app-store-versions: list<string> # the fields to include for returned resources of type appStoreVersions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/appStoreVersion"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[appStoreVersions]", var: fields_app_store_versions, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_app_store_versions: $fields_app_store_versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/betaAppReviewSubmission
#
# Returns: record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: builds-betaAppReviewSubmission-get_to_one_related
export def "builds-beta-app-review-submission-get-to-one-related" [
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
  --fields-beta-app-review-submissions: list<string> # the fields to include for returned resources of type betaAppReviewSubmissions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/betaAppReviewSubmission"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaAppReviewSubmissions]", var: fields_beta_app_review_submissions, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_app_review_submissions: $fields_beta_app_review_submissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/betaBuildLocalizations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-betaBuildLocalizations-get_to_many_related
export def "builds-beta-build-localizations-get-to-many-related" [
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
  --fields-beta-build-localizations: list<string> # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/betaBuildLocalizations"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaBuildLocalizations]", var: fields_beta_build_localizations, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_build_localizations: $fields_beta_build_localizations, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/buildBetaDetail
#
# Returns: record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: builds-buildBetaDetail-get_to_one_related
export def "builds-build-beta-detail-get-to-one-related" [
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
  --fields-build-beta-details: list<string> # the fields to include for returned resources of type buildBetaDetails
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/buildBetaDetail"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[buildBetaDetails]", var: fields_build_beta_details, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_build_beta_details: $fields_build_beta_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/diagnosticSignatures
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, included: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-diagnosticSignatures-get_to_many_related
export def "builds-diagnostic-signatures-get-to-many-related" [
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
  --filter-diagnostic-type: list<string> # filter by attribute 'diagnosticType'
  --fields-diagnostic-signatures: list<string> # the fields to include for returned resources of type diagnosticSignatures
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/diagnosticSignatures"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[diagnosticType]", var: filter_diagnostic_type, style: csv}, {name: "fields[diagnosticSignatures]", var: fields_diagnostic_signatures, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_diagnostic_type: $filter_diagnostic_type, fields_diagnostic_signatures: $fields_diagnostic_signatures, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/icons
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-icons-get_to_many_related
export def "builds-icons-get-to-many-related" [
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
  --fields-build-icons: list<string> # the fields to include for returned resources of type buildIcons
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/icons"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[buildIcons]", var: fields_build_icons, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_build_icons: $fields_build_icons, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/individualTesters
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-individualTesters-get_to_many_related
export def "builds-individual-testers-get-to-many-related" [
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
  --fields-beta-testers: list<string> # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/individualTesters"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[betaTesters]", var: fields_beta_testers, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_beta_testers: $fields_beta_testers, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/perfPowerMetrics
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-perfPowerMetrics-get_to_many_related
export def "builds-perf-power-metrics-get-to-many-related" [
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
  --filter-device-type: list<string> # filter by attribute 'deviceType'
  --filter-metric-type: list<string> # filter by attribute 'metricType'
  --filter-platform: list<string> # filter by attribute 'platform'
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/perfPowerMetrics"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[deviceType]", var: filter_device_type, style: csv}, {name: "filter[metricType]", var: filter_metric_type, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_device_type: $filter_device_type, filter_metric_type: $filter_metric_type, filter_platform: $filter_platform
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/preReleaseVersion
#
# Returns: record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: builds-preReleaseVersion-get_to_one_related
export def "builds-pre-release-version-get-to-one-related" [
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
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/preReleaseVersion"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_pre_release_versions: $fields_pre_release_versions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/relationships/appEncryptionDeclaration
#
# Returns: record<data: record<id: string, type: string>, links: record<self: string>>
# operationId: builds-appEncryptionDeclaration-get_to_one_relationship
export def "builds-app-encryption-declaration-get-to-one-relationship" [
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
    path: "/v1/builds/{id}/relationships/appEncryptionDeclaration"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/builds/{id}/relationships/appEncryptionDeclaration
#
# operationId: builds-appEncryptionDeclaration-update_to_one_relationship
export def "builds-app-encryption-declaration-update-to-one-relationship" [
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
  data: record # shape: {id: string, type: "appEncryptionDeclarations"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/builds/{id}/relationships/appEncryptionDeclaration"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/builds/{id}/relationships/betaGroups
#
# operationId: builds-betaGroups-delete_to_many_relationship
export def "builds-beta-groups-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/builds/{id}/relationships/betaGroups"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/builds/{id}/relationships/betaGroups
#
# operationId: builds-betaGroups-create_to_many_relationship
export def "builds-beta-groups-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/builds/{id}/relationships/betaGroups"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/builds/{id}/relationships/individualTesters
#
# operationId: builds-individualTesters-delete_to_many_relationship
export def "builds-individual-testers-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/builds/{id}/relationships/individualTesters"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/builds/{id}/relationships/individualTesters
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: builds-individualTesters-get_to_many_relationship
export def "builds-individual-testers-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/builds/{id}/relationships/individualTesters"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/builds/{id}/relationships/individualTesters
#
# operationId: builds-individualTesters-create_to_many_relationship
export def "builds-individual-testers-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/builds/{id}/relationships/individualTesters"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/bundleIdCapabilities
#
# Returns: record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: bundleIdCapabilities-create_instance
export def "bundle-id-capabilities-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "bundleIdCapabilities"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bundleIdCapabilities"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/bundleIdCapabilities/{id}
#
# operationId: bundleIdCapabilities-delete_instance
export def "bundle-id-capabilities-delete-instance" [
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
    path: "/v1/bundleIdCapabilities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/bundleIdCapabilities/{id}
#
# Returns: record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: bundleIdCapabilities-update_instance
export def "bundle-id-capabilities-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "bundleIdCapabilities"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/bundleIdCapabilities/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/bundleIds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: bundleIds-get_collection
export def "bundle-ids-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-identifier: list<string> # filter by attribute 'identifier'
  --filter-name: list<string> # filter by attribute 'name'
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-seed-id: list<string> # filter by attribute 'seedId'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-bundle-ids: list<string> # the fields to include for returned resources of type bundleIds
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-bundle-id-capabilities: list<string> # the fields to include for returned resources of type bundleIdCapabilities
  --fields-profiles: list<string> # the fields to include for returned resources of type profiles
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-bundle-id-capabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limit-profiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bundleIds"
    query: [{name: "filter[identifier]", var: filter_identifier, style: csv}, {name: "filter[name]", var: filter_name, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[seedId]", var: filter_seed_id, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[bundleIds]", var: fields_bundle_ids, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[bundleIdCapabilities]", var: fields_bundle_id_capabilities, style: csv}, {name: "fields[profiles]", var: fields_profiles, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[bundleIdCapabilities]", var: limit_bundle_id_capabilities}, {name: "limit[profiles]", var: limit_profiles}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_identifier: $filter_identifier, filter_name: $filter_name, filter_platform: $filter_platform, filter_seed_id: $filter_seed_id, filter_id: $filter_id, sort: $sort, fields_bundle_ids: $fields_bundle_ids, limit: $limit, include: $include, fields_bundle_id_capabilities: $fields_bundle_id_capabilities, fields_profiles: $fields_profiles, fields_apps: $fields_apps, limit_bundle_id_capabilities: $limit_bundle_id_capabilities, limit_profiles: $limit_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/bundleIds
#
# Returns: record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: bundleIds-create_instance
export def "bundle-ids-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "bundleIds"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/bundleIds"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/bundleIds/{id}
#
# operationId: bundleIds-delete_instance
export def "bundle-ids-delete-instance" [
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
    path: "/v1/bundleIds/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/bundleIds/{id}
#
# Returns: record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: bundleIds-get_instance
export def "bundle-ids-get-instance" [
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
  --fields-bundle-ids: list<string> # the fields to include for returned resources of type bundleIds
  --include: list<string> # comma-separated list of relationships to include
  --fields-bundle-id-capabilities: list<string> # the fields to include for returned resources of type bundleIdCapabilities
  --fields-profiles: list<string> # the fields to include for returned resources of type profiles
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-bundle-id-capabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limit-profiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bundleIds/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[bundleIds]", var: fields_bundle_ids, style: csv}, {name: include, var: include, style: csv}, {name: "fields[bundleIdCapabilities]", var: fields_bundle_id_capabilities, style: csv}, {name: "fields[profiles]", var: fields_profiles, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[bundleIdCapabilities]", var: limit_bundle_id_capabilities}, {name: "limit[profiles]", var: limit_profiles}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_bundle_ids: $fields_bundle_ids, include: $include, fields_bundle_id_capabilities: $fields_bundle_id_capabilities, fields_profiles: $fields_profiles, fields_apps: $fields_apps, limit_bundle_id_capabilities: $limit_bundle_id_capabilities, limit_profiles: $limit_profiles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/bundleIds/{id}
#
# Returns: record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: bundleIds-update_instance
export def "bundle-ids-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "bundleIds"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/bundleIds/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/bundleIds/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: bundleIds-app-get_to_one_related
export def "bundle-ids-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bundleIds/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/bundleIds/{id}/bundleIdCapabilities
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: bundleIds-bundleIdCapabilities-get_to_many_related
export def "bundle-ids-bundle-id-capabilities-get-to-many-related" [
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
  --fields-bundle-id-capabilities: list<string> # the fields to include for returned resources of type bundleIdCapabilities
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bundleIds/{id}/bundleIdCapabilities"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[bundleIdCapabilities]", var: fields_bundle_id_capabilities, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_bundle_id_capabilities: $fields_bundle_id_capabilities, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/bundleIds/{id}/profiles
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: bundleIds-profiles-get_to_many_related
export def "bundle-ids-profiles-get-to-many-related" [
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
  --fields-profiles: list<string> # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/bundleIds/{id}/profiles"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[profiles]", var: fields_profiles, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_profiles: $fields_profiles, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/certificates
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: certificates-get_collection
export def "certificates-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-certificate-type: list<string> # filter by attribute 'certificateType'
  --filter-display-name: list<string> # filter by attribute 'displayName'
  --filter-serial-number: list<string> # filter by attribute 'serialNumber'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-certificates: list<string> # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/certificates"
    query: [{name: "filter[certificateType]", var: filter_certificate_type, style: csv}, {name: "filter[displayName]", var: filter_display_name, style: csv}, {name: "filter[serialNumber]", var: filter_serial_number, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[certificates]", var: fields_certificates, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_certificate_type: $filter_certificate_type, filter_display_name: $filter_display_name, filter_serial_number: $filter_serial_number, filter_id: $filter_id, sort: $sort, fields_certificates: $fields_certificates, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/certificates
#
# Returns: record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: certificates-create_instance
export def "certificates-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "certificates"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/certificates"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/certificates/{id}
#
# operationId: certificates-delete_instance
export def "certificates-delete-instance" [
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
    path: "/v1/certificates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/certificates/{id}
#
# Returns: record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: certificates-get_instance
export def "certificates-get-instance" [
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
  --fields-certificates: list<string> # the fields to include for returned resources of type certificates
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/certificates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[certificates]", var: fields_certificates, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_certificates: $fields_certificates
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/devices
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: devices-get_collection
export def "devices-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: list<string> # filter by attribute 'name'
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-status: list<string> # filter by attribute 'status'
  --filter-udid: list<string> # filter by attribute 'udid'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-devices: list<string> # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/devices"
    query: [{name: "filter[name]", var: filter_name, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[status]", var: filter_status, style: csv}, {name: "filter[udid]", var: filter_udid, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[devices]", var: fields_devices, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_name: $filter_name, filter_platform: $filter_platform, filter_status: $filter_status, filter_udid: $filter_udid, filter_id: $filter_id, sort: $sort, fields_devices: $fields_devices, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/devices
#
# Returns: record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: devices-create_instance
export def "devices-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "devices"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/devices"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/devices/{id}
#
# Returns: record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: devices-get_instance
export def "devices-get-instance" [
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
  --fields-devices: list<string> # the fields to include for returned resources of type devices
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/devices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[devices]", var: fields_devices, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_devices: $fields_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/devices/{id}
#
# Returns: record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>>
# operationId: devices-update_instance
export def "devices-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "devices"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/devices/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/diagnosticSignatures/{id}/logs
#
# Returns: record<data: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: diagnosticSignatures-logs-get_to_many_related
export def "diagnostic-signatures-logs-get-to-many-related" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/diagnosticSignatures/{id}/logs"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/endUserLicenseAgreements
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>
# operationId: endUserLicenseAgreements-create_instance
export def "end-user-license-agreements-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "endUserLicenseAgreements"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/endUserLicenseAgreements"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/endUserLicenseAgreements/{id}
#
# operationId: endUserLicenseAgreements-delete_instance
export def "end-user-license-agreements-delete-instance" [
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
    path: "/v1/endUserLicenseAgreements/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/endUserLicenseAgreements/{id}
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>
# operationId: endUserLicenseAgreements-get_instance
export def "end-user-license-agreements-get-instance" [
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
  --fields-end-user-license-agreements: list<string> # the fields to include for returned resources of type endUserLicenseAgreements
  --include: list<string> # comma-separated list of relationships to include
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --limit-territories: int # maximum number of related territories returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/endUserLicenseAgreements/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[endUserLicenseAgreements]", var: fields_end_user_license_agreements, style: csv}, {name: include, var: include, style: csv}, {name: "fields[territories]", var: fields_territories, style: csv}, {name: "limit[territories]", var: limit_territories}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_end_user_license_agreements: $fields_end_user_license_agreements, include: $include, fields_territories: $fields_territories, limit_territories: $limit_territories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/endUserLicenseAgreements/{id}
#
# Returns: record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>>
# operationId: endUserLicenseAgreements-update_instance
export def "end-user-license-agreements-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "endUserLicenseAgreements"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/endUserLicenseAgreements/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/endUserLicenseAgreements/{id}/territories
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: endUserLicenseAgreements-territories-get_to_many_related
export def "end-user-license-agreements-territories-get-to-many-related" [
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
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/endUserLicenseAgreements/{id}/territories"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[territories]", var: fields_territories, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_territories: $fields_territories, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/financeReports
#
# Returns: binary
# operationId: financeReports-get_collection
export def "finance-reports-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-region-code: list<string> # filter by attribute 'regionCode' (required)
  --filter-report-date: list<string> # filter by attribute 'reportDate' (required)
  --filter-report-type: list<string> # filter by attribute 'reportType' (required)
  --filter-vendor-number: list<string> # filter by attribute 'vendorNumber' (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/financeReports"
    query: [{name: "filter[regionCode]", var: filter_region_code, style: csv, required: true}, {name: "filter[reportDate]", var: filter_report_date, style: csv, required: true}, {name: "filter[reportType]", var: filter_report_type, style: csv, required: true}, {name: "filter[vendorNumber]", var: filter_vendor_number, style: csv, required: true}]
    accept: [gzip]
    ok: [200]
    auth: bearer
  } {
    filter_region_code: $filter_region_code, filter_report_date: $filter_report_date, filter_report_type: $filter_report_type, filter_vendor_number: $filter_vendor_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/gameCenterEnabledVersions/{id}/compatibleVersions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: gameCenterEnabledVersions-compatibleVersions-get_to_many_related
export def "game-center-enabled-versions-compatible-versions-get-to-many-related" [
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
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-version-string: list<string> # filter by attribute 'versionString'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-game-center-enabled-versions: list<string> # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/gameCenterEnabledVersions/{id}/compatibleVersions"
    path_params: [{name: id, var: id}]
    query: [{name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[versionString]", var: filter_version_string, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[gameCenterEnabledVersions]", var: fields_game_center_enabled_versions, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, filter_platform: $filter_platform, filter_version_string: $filter_version_string, filter_app: $filter_app, filter_id: $filter_id, sort: $sort, fields_game_center_enabled_versions: $fields_game_center_enabled_versions, fields_apps: $fields_apps, limit: $limit, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-delete_to_many_relationship
export def "game-center-enabled-versions-compatible-versions-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: gameCenterEnabledVersions-compatibleVersions-get_to_many_relationship
export def "game-center-enabled-versions-compatible-versions-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-replace_to_many_relationship
export def "game-center-enabled-versions-compatible-versions-replace-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-create_to_many_relationship
export def "game-center-enabled-versions-compatible-versions-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/idfaDeclarations
#
# Returns: record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: idfaDeclarations-create_instance
export def "idfa-declarations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "idfaDeclarations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/idfaDeclarations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/idfaDeclarations/{id}
#
# operationId: idfaDeclarations-delete_instance
export def "idfa-declarations-delete-instance" [
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
    path: "/v1/idfaDeclarations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/idfaDeclarations/{id}
#
# Returns: record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: idfaDeclarations-update_instance
export def "idfa-declarations-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "idfaDeclarations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/idfaDeclarations/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/inAppPurchases/{id}
#
# Returns: record<data: record<attributes: record<inAppPurchaseType: string, productId: string, referenceName: string, state: string>, id: string, links: record<self: string>, relationships: record<apps: record>, type: string>, links: record<self: string>>
# operationId: inAppPurchases-get_instance
export def "in-app-purchases-get-instance" [
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
  --fields-in-app-purchases: list<string> # the fields to include for returned resources of type inAppPurchases
  --include: list<string> # comma-separated list of relationships to include
  --limit-apps: int # maximum number of related apps returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/inAppPurchases/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[inAppPurchases]", var: fields_in_app_purchases, style: csv}, {name: include, var: include, style: csv}, {name: "limit[apps]", var: limit_apps}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_in_app_purchases: $fields_in_app_purchases, include: $include, limit_apps: $limit_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/preReleaseVersions
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: preReleaseVersions-get_collection
export def "pre-release-versions-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-builds-expired: list<string> # filter by attribute 'builds.expired'
  --filter-builds-processing-state: list<string> # filter by attribute 'builds.processingState'
  --filter-platform: list<string> # filter by attribute 'platform'
  --filter-version: list<string> # filter by attribute 'version'
  --filter-app: list<string> # filter by id(s) of related 'app'
  --filter-builds: list<string> # filter by id(s) of related 'builds'
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/preReleaseVersions"
    query: [{name: "filter[builds.expired]", var: filter_builds_expired, style: csv}, {name: "filter[builds.processingState]", var: filter_builds_processing_state, style: csv}, {name: "filter[platform]", var: filter_platform, style: csv}, {name: "filter[version]", var: filter_version, style: csv}, {name: "filter[app]", var: filter_app, style: csv}, {name: "filter[builds]", var: filter_builds, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_builds_expired: $filter_builds_expired, filter_builds_processing_state: $filter_builds_processing_state, filter_platform: $filter_platform, filter_version: $filter_version, filter_app: $filter_app, filter_builds: $filter_builds, sort: $sort, fields_pre_release_versions: $fields_pre_release_versions, limit: $limit, include: $include, fields_builds: $fields_builds, fields_apps: $fields_apps, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/preReleaseVersions/{id}
#
# Returns: record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: preReleaseVersions-get_instance
export def "pre-release-versions-get-instance" [
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
  --fields-pre-release-versions: list<string> # the fields to include for returned resources of type preReleaseVersions
  --include: list<string> # comma-separated list of relationships to include
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/preReleaseVersions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[preReleaseVersions]", var: fields_pre_release_versions, style: csv}, {name: include, var: include, style: csv}, {name: "fields[builds]", var: fields_builds, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[builds]", var: limit_builds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_pre_release_versions: $fields_pre_release_versions, include: $include, fields_builds: $fields_builds, fields_apps: $fields_apps, limit_builds: $limit_builds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/preReleaseVersions/{id}/app
#
# Returns: record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: preReleaseVersions-app-get_to_one_related
export def "pre-release-versions-app-get-to-one-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/preReleaseVersions/{id}/app"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/preReleaseVersions/{id}/builds
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: preReleaseVersions-builds-get_to_many_related
export def "pre-release-versions-builds-get-to-many-related" [
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
  --fields-builds: list<string> # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/preReleaseVersions/{id}/builds"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[builds]", var: fields_builds, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_builds: $fields_builds, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/profiles
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: profiles-get_collection
export def "profiles-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: list<string> # filter by attribute 'name'
  --filter-profile-state: list<string> # filter by attribute 'profileState'
  --filter-profile-type: list<string> # filter by attribute 'profileType'
  --filter-id: list<string> # filter by id(s)
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-profiles: list<string> # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-certificates: list<string> # the fields to include for returned resources of type certificates
  --fields-devices: list<string> # the fields to include for returned resources of type devices
  --fields-bundle-ids: list<string> # the fields to include for returned resources of type bundleIds
  --limit-certificates: int # maximum number of related certificates returned (when they are included)
  --limit-devices: int # maximum number of related devices returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/profiles"
    query: [{name: "filter[name]", var: filter_name, style: csv}, {name: "filter[profileState]", var: filter_profile_state, style: csv}, {name: "filter[profileType]", var: filter_profile_type, style: csv}, {name: "filter[id]", var: filter_id, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[profiles]", var: fields_profiles, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[certificates]", var: fields_certificates, style: csv}, {name: "fields[devices]", var: fields_devices, style: csv}, {name: "fields[bundleIds]", var: fields_bundle_ids, style: csv}, {name: "limit[certificates]", var: limit_certificates}, {name: "limit[devices]", var: limit_devices}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_name: $filter_name, filter_profile_state: $filter_profile_state, filter_profile_type: $filter_profile_type, filter_id: $filter_id, sort: $sort, fields_profiles: $fields_profiles, limit: $limit, include: $include, fields_certificates: $fields_certificates, fields_devices: $fields_devices, fields_bundle_ids: $fields_bundle_ids, limit_certificates: $limit_certificates, limit_devices: $limit_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/profiles
#
# Returns: record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: profiles-create_instance
export def "profiles-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "profiles"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/profiles/{id}
#
# operationId: profiles-delete_instance
export def "profiles-delete-instance" [
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
    path: "/v1/profiles/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/profiles/{id}
#
# Returns: record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: profiles-get_instance
export def "profiles-get-instance" [
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
  --fields-profiles: list<string> # the fields to include for returned resources of type profiles
  --include: list<string> # comma-separated list of relationships to include
  --fields-certificates: list<string> # the fields to include for returned resources of type certificates
  --fields-devices: list<string> # the fields to include for returned resources of type devices
  --fields-bundle-ids: list<string> # the fields to include for returned resources of type bundleIds
  --limit-certificates: int # maximum number of related certificates returned (when they are included)
  --limit-devices: int # maximum number of related devices returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[profiles]", var: fields_profiles, style: csv}, {name: include, var: include, style: csv}, {name: "fields[certificates]", var: fields_certificates, style: csv}, {name: "fields[devices]", var: fields_devices, style: csv}, {name: "fields[bundleIds]", var: fields_bundle_ids, style: csv}, {name: "limit[certificates]", var: limit_certificates}, {name: "limit[devices]", var: limit_devices}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_profiles: $fields_profiles, include: $include, fields_certificates: $fields_certificates, fields_devices: $fields_devices, fields_bundle_ids: $fields_bundle_ids, limit_certificates: $limit_certificates, limit_devices: $limit_devices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/profiles/{id}/bundleId
#
# Returns: record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>>
# operationId: profiles-bundleId-get_to_one_related
export def "profiles-bundle-id-get-to-one-related" [
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
  --fields-bundle-ids: list<string> # the fields to include for returned resources of type bundleIds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/profiles/{id}/bundleId"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[bundleIds]", var: fields_bundle_ids, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_bundle_ids: $fields_bundle_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/profiles/{id}/certificates
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: profiles-certificates-get_to_many_related
export def "profiles-certificates-get-to-many-related" [
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
  --fields-certificates: list<string> # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/profiles/{id}/certificates"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[certificates]", var: fields_certificates, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_certificates: $fields_certificates, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/profiles/{id}/devices
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: profiles-devices-get_to_many_related
export def "profiles-devices-get-to-many-related" [
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
  --fields-devices: list<string> # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/profiles/{id}/devices"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[devices]", var: fields_devices, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_devices: $fields_devices, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/routingAppCoverages
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: routingAppCoverages-create_instance
export def "routing-app-coverages-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "routingAppCoverages"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/routingAppCoverages"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/routingAppCoverages/{id}
#
# operationId: routingAppCoverages-delete_instance
export def "routing-app-coverages-delete-instance" [
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
    path: "/v1/routingAppCoverages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/routingAppCoverages/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: routingAppCoverages-get_instance
export def "routing-app-coverages-get-instance" [
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
  --fields-routing-app-coverages: list<string> # the fields to include for returned resources of type routingAppCoverages
  --include: list<string> # comma-separated list of relationships to include
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/routingAppCoverages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[routingAppCoverages]", var: fields_routing_app_coverages, style: csv}, {name: include, var: include, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_routing_app_coverages: $fields_routing_app_coverages, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/routingAppCoverages/{id}
#
# Returns: record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>>
# operationId: routingAppCoverages-update_instance
export def "routing-app-coverages-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, type: "routingAppCoverages"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/routingAppCoverages/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/salesReports
#
# Returns: binary
# operationId: salesReports-get_collection
export def "sales-reports-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-frequency: list<string> # filter by attribute 'frequency' (required)
  --filter-report-date: list<string> # filter by attribute 'reportDate'
  --filter-report-sub-type: list<string> # filter by attribute 'reportSubType' (required)
  --filter-report-type: list<string> # filter by attribute 'reportType' (required)
  --filter-vendor-number: list<string> # filter by attribute 'vendorNumber' (required)
  --filter-version: list<string> # filter by attribute 'version'
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/salesReports"
    query: [{name: "filter[frequency]", var: filter_frequency, style: csv, required: true}, {name: "filter[reportDate]", var: filter_report_date, style: csv}, {name: "filter[reportSubType]", var: filter_report_sub_type, style: csv, required: true}, {name: "filter[reportType]", var: filter_report_type, style: csv, required: true}, {name: "filter[vendorNumber]", var: filter_vendor_number, style: csv, required: true}, {name: "filter[version]", var: filter_version, style: csv}]
    accept: [gzip]
    ok: [200]
    auth: bearer
  } {
    filter_frequency: $filter_frequency, filter_report_date: $filter_report_date, filter_report_sub_type: $filter_report_sub_type, filter_report_type: $filter_report_type, filter_vendor_number: $filter_vendor_number, filter_version: $filter_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/territories
#
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: territories-get_collection
export def "territories-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-territories: list<string> # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/territories"
    query: [{name: "fields[territories]", var: fields_territories, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fields_territories: $fields_territories, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/userInvitations
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: userInvitations-get_collection
export def "user-invitations-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-email: list<string> # filter by attribute 'email'
  --filter-roles: list<string> # filter by attribute 'roles'
  --filter-visible-apps: list<string> # filter by id(s) of related 'visibleApps'
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-user-invitations: list<string> # the fields to include for returned resources of type userInvitations
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userInvitations"
    query: [{name: "filter[email]", var: filter_email, style: csv}, {name: "filter[roles]", var: filter_roles, style: csv}, {name: "filter[visibleApps]", var: filter_visible_apps, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[userInvitations]", var: fields_user_invitations, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[visibleApps]", var: limit_visible_apps}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_email: $filter_email, filter_roles: $filter_roles, filter_visible_apps: $filter_visible_apps, sort: $sort, fields_user_invitations: $fields_user_invitations, limit: $limit, include: $include, fields_apps: $fields_apps, limit_visible_apps: $limit_visible_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/userInvitations
#
# Returns: record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: userInvitations-create_instance
export def "user-invitations-create-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships?: record, type: "userInvitations"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/userInvitations"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/userInvitations/{id}
#
# operationId: userInvitations-delete_instance
export def "user-invitations-delete-instance" [
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
    path: "/v1/userInvitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/userInvitations/{id}
#
# Returns: record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: userInvitations-get_instance
export def "user-invitations-get-instance" [
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
  --fields-user-invitations: list<string> # the fields to include for returned resources of type userInvitations
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userInvitations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[userInvitations]", var: fields_user_invitations, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[visibleApps]", var: limit_visible_apps}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_user_invitations: $fields_user_invitations, include: $include, fields_apps: $fields_apps, limit_visible_apps: $limit_visible_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/userInvitations/{id}/visibleApps
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: userInvitations-visibleApps-get_to_many_related
export def "user-invitations-visible-apps-get-to-many-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userInvitations/{id}/visibleApps"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/users
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: users-get_collection
export def "users-get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-roles: list<string> # filter by attribute 'roles'
  --filter-username: list<string> # filter by attribute 'username'
  --filter-visible-apps: list<string> # filter by id(s) of related 'visibleApps'
  --sort: list<string> # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-users: list<string> # the fields to include for returned resources of type users
  --limit: int # maximum resources per page
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users"
    query: [{name: "filter[roles]", var: filter_roles, style: csv}, {name: "filter[username]", var: filter_username, style: csv}, {name: "filter[visibleApps]", var: filter_visible_apps, style: csv}, {name: sort, var: sort, style: csv}, {name: "fields[users]", var: fields_users, style: csv}, {name: limit, var: limit}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[visibleApps]", var: limit_visible_apps}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter_roles: $filter_roles, filter_username: $filter_username, filter_visible_apps: $filter_visible_apps, sort: $sort, fields_users: $fields_users, limit: $limit, include: $include, fields_apps: $fields_apps, limit_visible_apps: $limit_visible_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/users/{id}
#
# operationId: users-delete_instance
export def "users-delete-instance" [
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
    path: "/v1/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/users/{id}
#
# Returns: record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: users-get_instance
export def "users-get-instance" [
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
  --fields-users: list<string> # the fields to include for returned resources of type users
  --include: list<string> # comma-separated list of relationships to include
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[users]", var: fields_users, style: csv}, {name: include, var: include, style: csv}, {name: "fields[apps]", var: fields_apps, style: csv}, {name: "limit[visibleApps]", var: limit_visible_apps}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_users: $fields_users, include: $include, fields_apps: $fields_apps, limit_visible_apps: $limit_visible_apps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/users/{id}
#
# Returns: record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>>
# operationId: users-update_instance
export def "users-update-instance" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "users"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-delete_to_many_relationship
export def "users-visible-apps-delete-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/users/{id}/relationships/visibleApps"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/users/{id}/relationships/visibleApps
#
# Returns: record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: users-visibleApps-get_to_many_relationship
export def "users-visible-apps-get-to-many-relationship" [
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
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users/{id}/relationships/visibleApps"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-replace_to_many_relationship
export def "users-visible-apps-replace-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/users/{id}/relationships/visibleApps"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-create_to_many_relationship
export def "users-visible-apps-create-to-many-relationship" [
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
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/users/{id}/relationships/visibleApps"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v1/users/{id}/visibleApps
#
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>>
# operationId: users-visibleApps-get_to_many_related
export def "users-visible-apps-get-to-many-related" [
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
  --fields-apps: list<string> # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/users/{id}/visibleApps"
    path_params: [{name: id, var: id}]
    query: [{name: "fields[apps]", var: fields_apps, style: csv}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, fields_apps: $fields_apps, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
