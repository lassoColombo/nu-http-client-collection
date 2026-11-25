# Auto-generated client for ConfigCat Public Management API v1
# Source: https://api.apis.guru/v2/specs/configcat.com/v1/openapi.json
# Auth: --token flag or $env.CONFIGCAT_PUBLIC_MANAGEMENT_API_TOKEN

const CLIENT = {
  base_url: "https://api.configcat.com"
  token_env_var: "CONFIGCAT_PUBLIC_MANAGEMENT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
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

def base-url-completer [] { ["https://api.configcat.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/hal+json" "application/json"] }
def setting-type-completer [] { ["boolean" "double" "int" "string"] }
def integration-link-type-completer [] { ["jira" "monday" "trello"] }
def audit-log-type-completer [] { ["apiKeyAdded" "apiKeyConnected" "apiKeyRemoved" "autoProvisioningConfigurationChanged" "codeReferenceDeleted" "codeReferenceStaleBranchDeleted" "codeReferencesUploaded" "configChanged" "configCreated" "configDeleted" "configsReordered" "domainAdded" "domainRemoved" "domainSamlConfigured" "domainSamlDeleted" "domainVerified" "environmentChanged" "environmentCreated" "environmentDeleted" "environmentsReordered" "integrationAdded" "integrationChanged" "integrationLinkAdded" "integrationLinkRemoved" "integrationRemoved" "organizationAdded" "organizationAdminChanged" "organizationAdminDisabled2FA" "organizationAdminLeft" "organizationChanged" "organizationMemberJoined" "organizationMemberProductJoinRequestApproved" "organizationMemberProductJoinRequestRejected" "organizationMemberProductJoinRequested" "organizationRemoved" "organizationSubscriptionTypeChanged" "permissionGroupChanged" "permissionGroupCreated" "permissionGroupDefault" "permissionGroupDeleted" "productChanged" "productCreated" "productDeleted" "productOwnershipTransferred" "productsReordered" "publicApiAccessTokenAdded" "publicApiAccessTokenRemoved" "segmentChanged" "segmentCreated" "segmentDeleted" "settingChanged" "settingCreated" "settingDeleted" "settingTagAdded" "settingTagRemoved" "settingValueChanged" "settingsReordered" "subscriptionChanged" "tagAdded" "tagChanged" "tagRemoved" "teamMemberInvitationChanged" "teamMemberInvitationRejected" "teamMemberInvitationResent" "teamMemberInvitationRevoked" "teamMemberInvited" "teamMemberJoined" "teamMemberLeft" "teamMemberPermissionGroupChanged" "teamMemberRemoved" "webHookChanged" "webHookCreated" "webHookDeleted" "webhookSigningKeyCreated" "webhookSigningKeyDeleted"] }
def access-type-completer [] { ["custom" "full" "readOnly"] }
def new-environment-access-type-completer [] { ["full" "none" "readOnly"] }
def comparator-completer [] { ["contains" "doesNotContain" "isNotOneOf" "isOneOf" "numberDoesNotEqual" "numberEquals" "numberGreater" "numberGreaterOrEquals" "numberLess" "numberLessOrEquals" "semVerGreater" "semVerGreaterOrEquals" "semVerIsNotOneOf" "semVerIsOneOf" "semVerLess" "semVerLessOrEquals" "sensitiveIsNotOneOf" "sensitiveIsOneOf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-config: "record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    update-config: "record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    get-deleted-settings: "table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>"
    get-sdk-keys: "record<primary: string, secondary: string>"
    get-setting-values: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, readOnly: bool, settingValues: table<integrationLinks: list, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, rolloutPercentageItems: list, rolloutRules: list, setting: record, settingTags: list, updatedAt: string, value: any>>"
    get-settings: "table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>"
    create-setting: "record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>"
    get-environment: "record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>"
    update-environment: "record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>"
    delete-integration-link: "record<hasRemainingIntegrationLink: bool>"
    add-or-update-integration-link: "record<description: string, integrationLinkType: string, key: string, url: string>"
    get-setting-value: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    update-setting-value: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    replace-setting-value: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    get-integration-link-details: "record<allIntegrationLinkCount: int, details: table<config: record, environment: record, product: record, readOnly: bool, setting: record, status: string>>"
    jira-add-or-update-integration-link: "record<description: string, integrationLinkType: string, key: string, url: string>"
    get-me: "record<email: string, fullName: string>"
    get-organizations: "table<name: string, organizationId: string>"
    get-organization-auditlogs: "table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string>"
    get-organization-members: "table<email: string, fullName: string, userId: string>"
    create-product: "record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>"
    get-permission-group: "record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    update-permission-group: "record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    get-products: "table<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>"
    get-product: "record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>"
    update-product: "record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>"
    get-auditlogs: "table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string>"
    get-configs: "table<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>"
    create-config: "record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    get-environments: "table<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>"
    create-environment: "record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>"
    get-product-members: "table<email: string, fullName: string, permissionGroupId: int, productId: string, userId: string>"
    get-permission-groups: "table<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: list<record>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>"
    create-permission-group: "record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>"
    get-segments: "table<createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string, usage: int>"
    create-segment: "record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>"
    get-tags: "table<color: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, tagId: int>"
    create-tag: "record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>"
    get-segment: "record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>"
    update-segment: "record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>"
    get-setting: "record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>"
    update-setting: "record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>"
    get-setting-value-by-sdkkey: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    update-setting-value-by-sdkkey: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    replace-setting-value-by-sdkkey: "record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>"
    get-tag: "record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>"
    update-tag: "record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>"
    get-settings-by-tag: "table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-v1-code-references" "post-v1-code-references-delete-reports" "delete-config" "get-config" "update-config" "get-deleted-settings" "get-sdk-keys" "get-setting-values" "get-settings" "create-setting" "delete-environment" "get-environment" "update-environment" "delete-integration-link" "add-or-update-integration-link" "get-setting-value" "update-setting-value" "replace-setting-value" "get-integration-link-details" "post-v1-jira-connect" "jira-add-or-update-integration-link" "get-me" "get-organizations" "get-organization-auditlogs" "get-organization-members" "delete-organization-member" "add-member-to-group" "create-product" "delete-permission-group" "get-permission-group" "update-permission-group" "get-products" "delete-product" "get-product" "update-product" "get-auditlogs" "get-configs" "create-config" "get-environments" "create-environment" "get-product-members" "invite-member" "delete-product-member" "get-permission-groups" "create-permission-group" "get-segments" "create-segment" "get-tags" "create-tag" "delete-segment" "get-segment" "update-segment" "delete-setting" "get-setting" "update-setting" "get-setting-value-by-sdkkey" "update-setting-value-by-sdkkey" "replace-setting-value-by-sdkkey" "delete-tag" "get-tag" "update-tag" "get-settings-by-tag" "commands"] | sort) } | get name | first)
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

# POST /v1/code-references
export def "post-v1-code-references" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-branches: list<string> # The currently active branches of the repository. Each previously uploaded report that belongs to a non-reported active branch is being deleted. (nullable)
  branch: string # The source control branch on where the scan was performed. (Source of the branch selector on the ConfigCat Dashboard)
  --commit-hash: string # The related commit's hash. (Appears on the ConfigCat Dashboard) (nullable)
  --commit-url: string # The related commit's URL. (Appears on the ConfigCat Dashboard) (nullable)
  config_id: string # The Config's identifier the scanning was performed against. (format: uuid)
  --flag-references: list # The actual code reference collection. (nullable) — item shape: {references: list, settingId: int}
  repository: string # The source control repository that contains the scanned code. (Source of the repository selector on the ConfigCat Dashboard)
  --uploader: string # The scanning tool's name. (Appears on the ConfigCat Dashboard) (nullable)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/code-references"
    body: {content_type: "application/json", kind: json, fields: [{name: activeBranches, var: active_branches}, {name: branch, var: branch}, {name: commitHash, var: commit_hash}, {name: commitUrl, var: commit_url}, {name: configId, var: config_id}, {name: flagReferences, var: flag_references}, {name: repository, var: repository}, {name: uploader, var: uploader}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    active_branches: $active_branches, branch: $branch, commit_hash: $commit_hash, commit_url: $commit_url, config_id: $config_id, flag_references: $flag_references, repository: $repository, uploader: $uploader
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/code-references/delete-reports
export def "post-v1-code-references-delete-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # If it's set, only this branch's reports belonging to the given repository will be deleted. (nullable)
  config_id: string # The Config's identifier from where the reports should be deleted. (format: uuid)
  repository: string # The source control repository which's reports should be deleted.
  --setting-id: int # If it's set, only this setting's reports belonging to the given repository will be deleted. (nullable, format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/code-references/delete-reports"
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: configId, var: config_id}, {name: repository, var: repository}, {name: settingId, var: setting_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    branch: $branch, config_id: $config_id, repository: $repository, setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Config
#
# DELETE /v1/configs/{configId}
# operationId: delete-config
export def "delete-config" [
  config_id: string
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
    path: "/v1/configs/{configId}"
    path_params: [{name: configId, var: config_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Config
#
# GET /v1/configs/{configId}
# Returns: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: get-config
export def "get-config" [
  config_id: string
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
    path: "/v1/configs/{configId}"
    path_params: [{name: configId, var: config_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Config
#
# PUT /v1/configs/{configId}
# Returns: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: update-config
export def "update-config" [
  config_id: string
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
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/configs/{configId}"
    path_params: [{name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Deleted Settings
#
# GET /v1/configs/{configId}/deleted-settings
# Returns: table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>
# operationId: get-deleted-settings
export def "get-deleted-settings" [
  config_id: string
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
    path: "/v1/configs/{configId}/deleted-settings"
    path_params: [{name: configId, var: config_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get SDK Key
#
# GET /v1/configs/{configId}/environments/{environmentId}
# Returns: record<primary: string, secondary: string>
# operationId: get-sdk-keys
export def "get-sdk-keys" [
  config_id: string
  environment_id: string
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
    path: "/v1/configs/{configId}/environments/{environmentId}"
    path_params: [{name: configId, var: config_id}, {name: environmentId, var: environment_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get values
#
# GET /v1/configs/{configId}/environments/{environmentId}/values
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, readOnly: bool, settingValues: table<integrationLinks: list, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, rolloutPercentageItems: list, rolloutRules: list, setting: record, settingTags: list, updatedAt: string, value: any>>
# operationId: get-setting-values
export def "get-setting-values" [
  config_id: string
  environment_id: string
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
    path: "/v1/configs/{configId}/environments/{environmentId}/values"
    path_params: [{name: configId, var: config_id}, {name: environmentId, var: environment_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Flags
#
# GET /v1/configs/{configId}/settings
# Returns: table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>
# operationId: get-settings
export def "get-settings" [
  config_id: string
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
    path: "/v1/configs/{configId}/settings"
    path_params: [{name: configId, var: config_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    config_id: $config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Flag
#
# POST /v1/configs/{configId}/settings
# Returns: record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>
# operationId: create-setting
export def "create-setting" [
  config_id: string
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
  --hint: string # A short description for the setting, shown on the Dashboard UI. (nullable)
  --initial-values: list # Optional, initial values of the feature flag or setting in the given Environments. (nullable) — item shape: {environmentId?: string, value?: any}
  key: string # The key of the setting.
  name: string # The name of the setting, shown on the Dashboard UI.
  setting_type: string@setting-type-completer
  --tags: list<int> # The IDs of the tags which are attached to the setting. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/configs/{configId}/settings"
    path_params: [{name: configId, var: config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hint, var: hint}, {name: initialValues, var: initial_values}, {name: key, var: key}, {name: name, var: name}, {name: settingType, var: setting_type}, {name: tags, var: tags}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    config_id: $config_id, hint: $hint, initial_values: $initial_values, key: $key, name: $name, setting_type: $setting_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Environment
#
# DELETE /v1/environments/{environmentId}
# operationId: delete-environment
export def "delete-environment" [
  environment_id: string
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
    path: "/v1/environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Environment
#
# GET /v1/environments/{environmentId}
# Returns: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>
# operationId: get-environment
export def "get-environment" [
  environment_id: string
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
    path: "/v1/environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Environment
#
# PUT /v1/environments/{environmentId}
# Returns: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>
# operationId: update-environment
export def "update-environment" [
  environment_id: string
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
  --color: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/environments/{environmentId}"
    path_params: [{name: environmentId, var: environment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, color: $color, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Integration link
#
# DELETE /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# Returns: record<hasRemainingIntegrationLink: bool>
# operationId: delete-integration-link
export def "delete-integration-link" [
  environment_id: string
  setting_id: int
  integration_link_type: string@integration-link-type-completer
  key: string
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
    path: "/v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}, {name: integrationLinkType, var: integration_link_type}, {name: key, var: key}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id, integration_link_type: $integration_link_type, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add or update Integration link
#
# POST /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# Returns: record<description: string, integrationLinkType: string, key: string, url: string>
# operationId: add-or-update-integration-link
export def "add-or-update-integration-link" [
  environment_id: string
  setting_id: int
  integration_link_type: string@integration-link-type-completer
  key: string
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
  --description: string # nullable
  --url: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}, {name: integrationLinkType, var: integration_link_type}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: url, var: url}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id, integration_link_type: $integration_link_type, key: $key, description: $description, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get value
#
# GET /v1/environments/{environmentId}/settings/{settingId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: get-setting-value
export def "get-setting-value" [
  environment_id: string
  setting_id: int
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
    path: "/v1/environments/{environmentId}/settings/{settingId}/value"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update value
#
# PATCH /v1/environments/{environmentId}/settings/{settingId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: update-setting-value
export def "update-setting-value" [
  environment_id: string
  setting_id: int
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
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/environments/{environmentId}/settings/{settingId}/value"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}]
    query: [{name: reason, var: reason}]
    body: {content_type: "application/json", kind: json, fields: [{name: operations, var: operations}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200, 204]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id, reason: $reason, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace value
#
# PUT /v1/environments/{environmentId}/settings/{settingId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: replace-setting-value
export def "replace-setting-value" [
  environment_id: string
  setting_id: int
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
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --rollout-percentage-items: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rollout-rules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/environments/{environmentId}/settings/{settingId}/value"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}]
    query: [{name: reason, var: reason}]
    body: {content_type: "application/json", kind: json, fields: [{name: rolloutPercentageItems, var: rollout_percentage_items}, {name: rolloutRules, var: rollout_rules}, {name: value, var: value}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id, reason: $reason, rollout_percentage_items: $rollout_percentage_items, rollout_rules: $rollout_rules, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Integration link
#
# GET /v1/integrationLink/{integrationLinkType}/{key}/details
# Returns: record<allIntegrationLinkCount: int, details: table<config: record, environment: record, product: record, readOnly: bool, setting: record, status: string>>
# operationId: get-integration-link-details
export def "get-integration-link-details" [
  integration_link_type: string@integration-link-type-completer
  key: string
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
    path: "/v1/integrationLink/{integrationLinkType}/{key}/details"
    path_params: [{name: integrationLinkType, var: integration_link_type}, {name: key, var: key}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    integration_link_type: $integration_link_type, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /v1/jira/Connect
export def "post-v1-jira-connect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_key: string
  jira_jwt_token: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/jira/Connect"
    body: {content_type: "application/json", kind: json, fields: [{name: clientKey, var: client_key}, {name: jiraJwtToken, var: jira_jwt_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    client_key: $client_key, jira_jwt_token: $jira_jwt_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v1/jira/environments/{environmentId}/settings/{settingId}/integrationLinks/{key}
#
# Returns: record<description: string, integrationLinkType: string, key: string, url: string>
# operationId: jira-add-or-update-integration-link
export def "jira-add-or-update-integration-link" [
  environment_id: string
  setting_id: int
  key: string
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
  client_key: string
  --description: string # nullable
  jira_jwt_token: string
  --url: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/jira/environments/{environmentId}/settings/{settingId}/integrationLinks/{key}"
    path_params: [{name: environmentId, var: environment_id}, {name: settingId, var: setting_id}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientKey, var: client_key}, {name: description, var: description}, {name: jiraJwtToken, var: jira_jwt_token}, {name: url, var: url}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    environment_id: $environment_id, setting_id: $setting_id, key: $key, client_key: $client_key, description: $description, jira_jwt_token: $jira_jwt_token, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get authenticated user details
#
# GET /v1/me
# Returns: record<email: string, fullName: string>
# operationId: get-me
export def "get-me" [
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
    path: "/v1/me"
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Organizations
#
# GET /v1/organizations
# Returns: table<name: string, organizationId: string>
# operationId: get-organizations
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/organizations"
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Audit log items for Organization
#
# GET /v1/organizations/{organizationId}/auditlogs
# Returns: table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string>
# operationId: get-organization-auditlogs
export def "get-organization-auditlogs" [
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
  --accept: string@accept-completer # Response content type
  --product-id: string # The identifier of the Product. (format: uuid)
  --config-id: string # The identifier of the Config. (format: uuid)
  --environment-id: string # The identifier of the Environment. (format: uuid)
  --audit-log-type: string@audit-log-type-completer # Filter Audit logs by Audit log type. (nullable)
  --from-utc-date-time: string # Filter Audit logs by starting UTC date. (format: date-time)
  --to-utc-date-time: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/organizations/{organizationId}/auditlogs"
    path_params: [{name: organizationId, var: organization_id}]
    query: [{name: productId, var: product_id}, {name: configId, var: config_id}, {name: environmentId, var: environment_id}, {name: auditLogType, var: audit_log_type}, {name: fromUtcDateTime, var: from_utc_date_time}, {name: toUtcDateTime, var: to_utc_date_time}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    organization_id: $organization_id, product_id: $product_id, config_id: $config_id, environment_id: $environment_id, audit_log_type: $audit_log_type, from_utc_date_time: $from_utc_date_time, to_utc_date_time: $to_utc_date_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Organization Members
#
# GET /v1/organizations/{organizationId}/members
# Returns: table<email: string, fullName: string, userId: string>
# operationId: get-organization-members
export def "get-organization-members" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/organizations/{organizationId}/members"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Member from Organization
#
# DELETE /v1/organizations/{organizationId}/members/{userId}
# operationId: delete-organization-member
export def "delete-organization-member" [
  organization_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/organizations/{organizationId}/members/{userId}"
    path_params: [{name: organizationId, var: organization_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    organization_id: $organization_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Member Permissions
#
# POST /v1/organizations/{organizationId}/members/{userId}
# operationId: add-member-to-group
export def "add-member-to-group" [
  organization_id: string
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
  permission_group_ids: list<int>
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/organizations/{organizationId}/members/{userId}"
    path_params: [{name: organizationId, var: organization_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissionGroupIds, var: permission_group_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    organization_id: $organization_id, user_id: $user_id, permission_group_ids: $permission_group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Product
#
# POST /v1/organizations/{organizationId}/products
# Returns: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>
# operationId: create-product
export def "create-product" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/organizations/{organizationId}/products"
    path_params: [{name: organizationId, var: organization_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    organization_id: $organization_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Permission Group
#
# DELETE /v1/permissions/{permissionGroupId}
# operationId: delete-permission-group
export def "delete-permission-group" [
  permission_group_id: int
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
    path: "/v1/permissions/{permissionGroupId}"
    path_params: [{name: permissionGroupId, var: permission_group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    permission_group_id: $permission_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Permission Group
#
# GET /v1/permissions/{permissionGroupId}
# Returns: record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: get-permission-group
export def "get-permission-group" [
  permission_group_id: int
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
    path: "/v1/permissions/{permissionGroupId}"
    path_params: [{name: permissionGroupId, var: permission_group_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    permission_group_id: $permission_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Permission Group
#
# PUT /v1/permissions/{permissionGroupId}
# Returns: record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: update-permission-group
export def "update-permission-group" [
  permission_group_id: int
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
  --access-type: string@access-type-completer
  --can-create-or-update-config: oneof<nothing, bool> # nullable
  --can-create-or-update-environment: oneof<nothing, bool> # nullable
  --can-create-or-update-segments: oneof<nothing, bool> # nullable
  --can-create-or-update-setting: oneof<nothing, bool> # nullable
  --can-create-or-update-tag: oneof<nothing, bool> # nullable
  --can-delete-config: oneof<nothing, bool> # nullable
  --can-delete-environment: oneof<nothing, bool> # nullable
  --can-delete-segments: oneof<nothing, bool> # nullable
  --can-delete-setting: oneof<nothing, bool> # nullable
  --can-delete-tag: oneof<nothing, bool> # nullable
  --can-manage-integrations: oneof<nothing, bool> # nullable
  --can-manage-members: oneof<nothing, bool> # nullable
  --can-manage-product-preferences: oneof<nothing, bool> # nullable
  --can-manage-webhook: oneof<nothing, bool> # nullable
  --can-rotate-sdk-key: oneof<nothing, bool> # nullable
  --can-tag-setting: oneof<nothing, bool> # nullable
  --can-use-export-import: oneof<nothing, bool> # nullable
  --can-view-product-audit-log: oneof<nothing, bool> # nullable
  --can-view-product-statistics: oneof<nothing, bool> # nullable
  --can-view-sdk-key: oneof<nothing, bool> # nullable
  --environment-accesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  --name: string # nullable
  --new-environment-access-type: string@new-environment-access-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/permissions/{permissionGroupId}"
    path_params: [{name: permissionGroupId, var: permission_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessType, var: access_type}, {name: canCreateOrUpdateConfig, var: can_create_or_update_config}, {name: canCreateOrUpdateEnvironment, var: can_create_or_update_environment}, {name: canCreateOrUpdateSegments, var: can_create_or_update_segments}, {name: canCreateOrUpdateSetting, var: can_create_or_update_setting}, {name: canCreateOrUpdateTag, var: can_create_or_update_tag}, {name: canDeleteConfig, var: can_delete_config}, {name: canDeleteEnvironment, var: can_delete_environment}, {name: canDeleteSegments, var: can_delete_segments}, {name: canDeleteSetting, var: can_delete_setting}, {name: canDeleteTag, var: can_delete_tag}, {name: canManageIntegrations, var: can_manage_integrations}, {name: canManageMembers, var: can_manage_members}, {name: canManageProductPreferences, var: can_manage_product_preferences}, {name: canManageWebhook, var: can_manage_webhook}, {name: canRotateSdkKey, var: can_rotate_sdk_key}, {name: canTagSetting, var: can_tag_setting}, {name: canUseExportImport, var: can_use_export_import}, {name: canViewProductAuditLog, var: can_view_product_audit_log}, {name: canViewProductStatistics, var: can_view_product_statistics}, {name: canViewSdkKey, var: can_view_sdk_key}, {name: environmentAccesses, var: environment_accesses}, {name: name, var: name}, {name: newEnvironmentAccessType, var: new_environment_access_type}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    permission_group_id: $permission_group_id, access_type: $access_type, can_create_or_update_config: $can_create_or_update_config, can_create_or_update_environment: $can_create_or_update_environment, can_create_or_update_segments: $can_create_or_update_segments, can_create_or_update_setting: $can_create_or_update_setting, can_create_or_update_tag: $can_create_or_update_tag, can_delete_config: $can_delete_config, can_delete_environment: $can_delete_environment, can_delete_segments: $can_delete_segments, can_delete_setting: $can_delete_setting, can_delete_tag: $can_delete_tag, can_manage_integrations: $can_manage_integrations, can_manage_members: $can_manage_members, can_manage_product_preferences: $can_manage_product_preferences, can_manage_webhook: $can_manage_webhook, can_rotate_sdk_key: $can_rotate_sdk_key, can_tag_setting: $can_tag_setting, can_use_export_import: $can_use_export_import, can_view_product_audit_log: $can_view_product_audit_log, can_view_product_statistics: $can_view_product_statistics, can_view_sdk_key: $can_view_sdk_key, environment_accesses: $environment_accesses, name: $name, new_environment_access_type: $new_environment_access_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Products
#
# GET /v1/products
# Returns: table<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>
# operationId: get-products
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products"
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Product
#
# DELETE /v1/products/{productId}
# operationId: delete-product
export def "delete-product" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/products/{productId}"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product
#
# GET /v1/products/{productId}
# Returns: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>
# operationId: get-product
export def "get-product" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Product
#
# PUT /v1/products/{productId}
# Returns: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>
# operationId: update-product
export def "update-product" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/products/{productId}"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Audit log items for Product
#
# GET /v1/products/{productId}/auditlogs
# Returns: table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string>
# operationId: get-auditlogs
export def "get-auditlogs" [
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
  --accept: string@accept-completer # Response content type
  --config-id: string # The identifier of the Config. (format: uuid)
  --environment-id: string # The identifier of the Environment. (format: uuid)
  --audit-log-type: string@audit-log-type-completer # Filter Audit logs by Audit log type. (nullable)
  --from-utc-date-time: string # Filter Audit logs by starting UTC date. (format: date-time)
  --to-utc-date-time: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/auditlogs"
    path_params: [{name: productId, var: product_id}]
    query: [{name: configId, var: config_id}, {name: environmentId, var: environment_id}, {name: auditLogType, var: audit_log_type}, {name: fromUtcDateTime, var: from_utc_date_time}, {name: toUtcDateTime, var: to_utc_date_time}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id, config_id: $config_id, environment_id: $environment_id, audit_log_type: $audit_log_type, from_utc_date_time: $from_utc_date_time, to_utc_date_time: $to_utc_date_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Configs
#
# GET /v1/products/{productId}/configs
# Returns: table<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>
# operationId: get-configs
export def "get-configs" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/configs"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Config
#
# POST /v1/products/{productId}/configs
# Returns: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: create-config
export def "create-config" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/configs"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    product_id: $product_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Environments
#
# GET /v1/products/{productId}/environments
# Returns: table<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>
# operationId: get-environments
export def "get-environments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/environments"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Environment
#
# POST /v1/products/{productId}/environments
# Returns: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool>
# operationId: create-environment
export def "create-environment" [
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
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --description: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/environments"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    product_id: $product_id, color: $color, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Product Members
#
# GET /v1/products/{productId}/members
# Returns: table<email: string, fullName: string, permissionGroupId: int, productId: string, userId: string>
# operationId: get-product-members
export def "get-product-members" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/members"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite Member
#
# POST /v1/products/{productId}/members/invite
# operationId: invite-member
export def "invite-member" [
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
  emails: list<string>
  permission_group_id: int # format: int64
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/members/invite"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: permissionGroupId, var: permission_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id, emails: $emails, permission_group_id: $permission_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Member from Product
#
# DELETE /v1/products/{productId}/members/{userId}
# operationId: delete-product-member
export def "delete-product-member" [
  product_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/products/{productId}/members/{userId}"
    path_params: [{name: productId, var: product_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    product_id: $product_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Permission Groups
#
# GET /v1/products/{productId}/permissions
# Returns: table<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: list<record>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>
# operationId: get-permission-groups
export def "get-permission-groups" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/permissions"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Permission Group
#
# POST /v1/products/{productId}/permissions
# Returns: record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>>
# operationId: create-permission-group
export def "create-permission-group" [
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
  --accept: string@accept-completer # Response content type
  --access-type: string@access-type-completer
  --can-create-or-update-config: oneof<nothing, bool>
  --can-create-or-update-environment: oneof<nothing, bool>
  --can-create-or-update-segments: oneof<nothing, bool>
  --can-create-or-update-setting: oneof<nothing, bool>
  --can-create-or-update-tag: oneof<nothing, bool>
  --can-delete-config: oneof<nothing, bool>
  --can-delete-environment: oneof<nothing, bool>
  --can-delete-segments: oneof<nothing, bool>
  --can-delete-setting: oneof<nothing, bool>
  --can-delete-tag: oneof<nothing, bool>
  --can-manage-integrations: oneof<nothing, bool>
  --can-manage-members: oneof<nothing, bool>
  --can-manage-product-preferences: oneof<nothing, bool>
  --can-manage-webhook: oneof<nothing, bool>
  --can-rotate-sdk-key: oneof<nothing, bool>
  --can-tag-setting: oneof<nothing, bool>
  --can-use-export-import: oneof<nothing, bool>
  --can-view-product-audit-log: oneof<nothing, bool>
  --can-view-product-statistics: oneof<nothing, bool>
  --can-view-sdk-key: oneof<nothing, bool>
  --environment-accesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  name: string
  --new-environment-access-type: string@new-environment-access-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/permissions"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessType, var: access_type}, {name: canCreateOrUpdateConfig, var: can_create_or_update_config}, {name: canCreateOrUpdateEnvironment, var: can_create_or_update_environment}, {name: canCreateOrUpdateSegments, var: can_create_or_update_segments}, {name: canCreateOrUpdateSetting, var: can_create_or_update_setting}, {name: canCreateOrUpdateTag, var: can_create_or_update_tag}, {name: canDeleteConfig, var: can_delete_config}, {name: canDeleteEnvironment, var: can_delete_environment}, {name: canDeleteSegments, var: can_delete_segments}, {name: canDeleteSetting, var: can_delete_setting}, {name: canDeleteTag, var: can_delete_tag}, {name: canManageIntegrations, var: can_manage_integrations}, {name: canManageMembers, var: can_manage_members}, {name: canManageProductPreferences, var: can_manage_product_preferences}, {name: canManageWebhook, var: can_manage_webhook}, {name: canRotateSdkKey, var: can_rotate_sdk_key}, {name: canTagSetting, var: can_tag_setting}, {name: canUseExportImport, var: can_use_export_import}, {name: canViewProductAuditLog, var: can_view_product_audit_log}, {name: canViewProductStatistics, var: can_view_product_statistics}, {name: canViewSdkKey, var: can_view_sdk_key}, {name: environmentAccesses, var: environment_accesses}, {name: name, var: name}, {name: newEnvironmentAccessType, var: new_environment_access_type}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    product_id: $product_id, access_type: $access_type, can_create_or_update_config: $can_create_or_update_config, can_create_or_update_environment: $can_create_or_update_environment, can_create_or_update_segments: $can_create_or_update_segments, can_create_or_update_setting: $can_create_or_update_setting, can_create_or_update_tag: $can_create_or_update_tag, can_delete_config: $can_delete_config, can_delete_environment: $can_delete_environment, can_delete_segments: $can_delete_segments, can_delete_setting: $can_delete_setting, can_delete_tag: $can_delete_tag, can_manage_integrations: $can_manage_integrations, can_manage_members: $can_manage_members, can_manage_product_preferences: $can_manage_product_preferences, can_manage_webhook: $can_manage_webhook, can_rotate_sdk_key: $can_rotate_sdk_key, can_tag_setting: $can_tag_setting, can_use_export_import: $can_use_export_import, can_view_product_audit_log: $can_view_product_audit_log, can_view_product_statistics: $can_view_product_statistics, can_view_sdk_key: $can_view_sdk_key, environment_accesses: $environment_accesses, name: $name, new_environment_access_type: $new_environment_access_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Segments
#
# GET /v1/products/{productId}/segments
# Returns: table<createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string, usage: int>
# operationId: get-segments
export def "get-segments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/segments"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Segment
#
# POST /v1/products/{productId}/segments
# Returns: record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>
# operationId: create-segment
export def "create-segment" [
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
  --accept: string@accept-completer # Response content type
  comparator: string@comparator-completer
  comparison_attribute: string
  comparison_value: string
  --description: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/segments"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comparator, var: comparator}, {name: comparisonAttribute, var: comparison_attribute}, {name: comparisonValue, var: comparison_value}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    product_id: $product_id, comparator: $comparator, comparison_attribute: $comparison_attribute, comparison_value: $comparison_value, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Tags
#
# GET /v1/products/{productId}/tags
# Returns: table<color: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, tagId: int>
# operationId: get-tags
export def "get-tags" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/products/{productId}/tags"
    path_params: [{name: productId, var: product_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    product_id: $product_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Tag
#
# POST /v1/products/{productId}/tags
# Returns: record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>
# operationId: create-tag
export def "create-tag" [
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
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/products/{productId}/tags"
    path_params: [{name: productId, var: product_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [201]
    auth: basic
  } {
    product_id: $product_id, color: $color, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Segment
#
# DELETE /v1/segments/{segmentId}
# operationId: delete-segment
export def "delete-segment" [
  segment_id: string
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
    path: "/v1/segments/{segmentId}"
    path_params: [{name: segmentId, var: segment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Segment
#
# GET /v1/segments/{segmentId}
# Returns: record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>
# operationId: get-segment
export def "get-segment" [
  segment_id: string
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
    path: "/v1/segments/{segmentId}"
    path_params: [{name: segmentId, var: segment_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Segment
#
# PUT /v1/segments/{segmentId}
# Returns: record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string>
# operationId: update-segment
export def "update-segment" [
  segment_id: string
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
  --comparator: string@comparator-completer
  --comparison-attribute: string # nullable
  --comparison-value: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/segments/{segmentId}"
    path_params: [{name: segmentId, var: segment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comparator, var: comparator}, {name: comparisonAttribute, var: comparison_attribute}, {name: comparisonValue, var: comparison_value}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    segment_id: $segment_id, comparator: $comparator, comparison_attribute: $comparison_attribute, comparison_value: $comparison_value, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Flag
#
# DELETE /v1/settings/{settingId}
# operationId: delete-setting
export def "delete-setting" [
  setting_id: int
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
    path: "/v1/settings/{settingId}"
    path_params: [{name: settingId, var: setting_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Flag
#
# GET /v1/settings/{settingId}
# Returns: record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>
# operationId: get-setting
export def "get-setting" [
  setting_id: int
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
    path: "/v1/settings/{settingId}"
    path_params: [{name: settingId, var: setting_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    setting_id: $setting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Flag
#
# PATCH /v1/settings/{settingId}
# Returns: record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>>
# operationId: update-setting
export def "update-setting" [
  setting_id: int
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
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/settings/{settingId}"
    path_params: [{name: settingId, var: setting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: operations, var: operations}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    setting_id: $setting_id, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get value
#
# GET /v1/settings/{settingKeyOrId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: get-setting-value-by-sdkkey
export def "get-setting-value-by-sdkkey" [
  setting_key_or_id: string
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
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/settings/{settingKeyOrId}/value"
    path_params: [{name: settingKeyOrId, var: setting_key_or_id}]
    header: [{name: X-CONFIGCAT-SDKKEY, var: x_configcat_sdkkey}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    setting_key_or_id: $setting_key_or_id, x_configcat_sdkkey: $x_configcat_sdkkey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update value
#
# PATCH /v1/settings/{settingKeyOrId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: update-setting-value-by-sdkkey
export def "update-setting-value-by-sdkkey" [
  setting_key_or_id: string
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
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/settings/{settingKeyOrId}/value"
    path_params: [{name: settingKeyOrId, var: setting_key_or_id}]
    query: [{name: reason, var: reason}]
    header: [{name: X-CONFIGCAT-SDKKEY, var: x_configcat_sdkkey}]
    body: {content_type: "application/json", kind: json, fields: [{name: operations, var: operations}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200, 204]
    auth: basic
  } {
    setting_key_or_id: $setting_key_or_id, reason: $reason, x_configcat_sdkkey: $x_configcat_sdkkey, operations: $operations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace value
#
# PUT /v1/settings/{settingKeyOrId}/value
# Returns: record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any>
# operationId: replace-setting-value-by-sdkkey
export def "replace-setting-value-by-sdkkey" [
  setting_key_or_id: string
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
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --rollout-percentage-items: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rollout-rules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/settings/{settingKeyOrId}/value"
    path_params: [{name: settingKeyOrId, var: setting_key_or_id}]
    query: [{name: reason, var: reason}]
    header: [{name: X-CONFIGCAT-SDKKEY, var: x_configcat_sdkkey}]
    body: {content_type: "application/json", kind: json, fields: [{name: rolloutPercentageItems, var: rollout_percentage_items}, {name: rolloutRules, var: rollout_rules}, {name: value, var: value}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    setting_key_or_id: $setting_key_or_id, reason: $reason, x_configcat_sdkkey: $x_configcat_sdkkey, rollout_percentage_items: $rollout_percentage_items, rollout_rules: $rollout_rules, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Tag
#
# DELETE /v1/tags/{tagId}
# operationId: delete-tag
export def "delete-tag" [
  tag_id: int
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
    path: "/v1/tags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tag
#
# GET /v1/tags/{tagId}
# Returns: record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>
# operationId: get-tag
export def "get-tag" [
  tag_id: int
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
    path: "/v1/tags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Tag
#
# PUT /v1/tags/{tagId}
# Returns: record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int>
# operationId: update-tag
export def "update-tag" [
  tag_id: int
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
  --color: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/tags/{tagId}"
    path_params: [{name: tagId, var: tag_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}]}
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    tag_id: $tag_id, color: $color, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Settings by Tag
#
# GET /v1/tags/{tagId}/settings
# Returns: table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>>
# operationId: get-settings-by-tag
export def "get-settings-by-tag" [
  tag_id: int
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
    path: "/v1/tags/{tagId}/settings"
    path_params: [{name: tagId, var: tag_id}]
    accept: ["application/hal+json", "application/json"]
    ok: [200]
    auth: basic
  } {
    tag_id: $tag_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
