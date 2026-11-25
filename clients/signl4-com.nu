# Auto-generated client for SIGNL4 API v1
# Source: https://api.apis.guru/v2/specs/signl4.com/v1/openapi.json
# Auth: --token flag or $env.SIGNL4_API_TOKEN

const CLIENT = {
  base_url: "https://connect.signl4.com/api"
  token_env_var: "SIGNL4_API_TOKEN"
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

def base-url-completer [] { ["https://connect.signl4.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def severity-completer [] { ["0" "1" "2"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def scope-completer [] { ["0" "1" "2"] }
def status-codes-completer [] { ["0" "1" "16" "2" "32" "4" "8"] }
def keyword-matching-completer [] { ["0" "1"] }
def options-completer [] { ["0" "1" "2" "4" "8"] }
def event-status-code-completer [] { ["0" "1" "1000" "2" "3" "4" "5" "6"] }
def filter-action-completer [] { ["0" "1" "2"] }
def filter-mode-completer [] { ["0" "1"] }
def opt-out-mode-completer [] { ["0" "1" "2"] }
def persistent-notificication-mode-completer [] { ["0" "1"] }
def response-mode-completer [] { ["2" "4"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-alerts: "record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    post-alerts-paged: "record<continuationToken: record<nextPartitionKey: string, nextRowKey: string, nextTableName: string>, hasMore: bool, results: table<alertDeliveryStatus: record, annotations: list, categoryId: string, eventId: string, flags: int, historyDetailed: record, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>>"
    get-alerts-report: "record<last24Hours: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, subscriptionId: string, teamCurrentDuty: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, teamId: string, teamLastDuty: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, userId: string, userLastDutyChange: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>>"
    get-alerts-alert-id: "record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    post-alerts-alert-id-acknowledge: "record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    post-alerts-alert-id-annotate: "record<annotationType: int, id: string, text: string, timestamp: string, userId: string>"
    get-alerts-alert-id-annotations: "table<annotationType: int, id: string, text: string, timestamp: string, userId: string>"
    get-alerts-alert-id-attachments: "table<contentType: string, id: string, name: string>"
    get-alerts-alert-id-attachments-attachment-id: "binary"
    post-alerts-alert-id-close: "record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    get-alerts-alert-id-notifications: "table<address: string, channelType: int, deviceName: string, lastUpdate: string, messageStatus: int, userId: string, userStatus: int>"
    get-alerts-alert-id-overview: "record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    post-alerts-alert-id-undo-acknowledge: "record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    post-alerts-alert-id-undo-close: "record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>"
    get-categories-images: "list<string>"
    get-categories-team-id: "table<augmentations: list<record>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>"
    post-categories-team-id: "record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>"
    get-categories-team-id-metrics: "table<categoryId: string, last24Hours: int, lastAlert: string, subscriberCount: int>"
    get-categories-team-id-category-id: "record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>"
    put-categories-team-id-category-id: "record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>"
    get-categories-team-id-category-id-metrics: "record<categoryId: string, last24Hours: int, lastAlert: string, subscriberCount: int>"
    get-categories-team-id-category-id-subscriptions: "table<status: int, userId: string>"
    post-categories-team-id-category-id-subscriptions: "table<status: int, userId: string>"
    post-events-paged: "record<continuationToken: record<nextPartitionKey: string, nextRowKey: string, nextTableName: string>, hasMore: bool, results: table<acknowledgedAlerts: list, alertId: string, categoryId: string, closedAlerts: list, creationTime: string, eventSourceType: int, eventStatus: int, id: string, lastModified: string, severity: int, teamId: string, text: string, title: string>>"
    get-events-event-id-overview: "record<acknowledgedAlerts: list<string>, alertId: string, categoryId: string, closedAlerts: list<string>, creationTime: string, eventSourceType: int, eventStatus: int, id: string, lastModified: string, severity: int, teamId: string, text: string, title: string>"
    get-events-event-id-parameters: "table<name: string, order: int, type: int, value: string>"
    get-prepaid-balance: "record<balance: int, latestTopUp: string, pendingTransaction: bool>"
    get-prepaid-settings: "record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>"
    put-prepaid-settings: "record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>"
    get-prepaid-transactions: "table<autoTopUpId: string, created: string, createdBy: string, credits: int, currency: string, modified: string, packageCode: string, status: string, statusCode: int, subscriptionId: string, transactionId: string>"
    get-scripts-instances: "table<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    post-scripts-instances: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    get-scripts-instances-instance-id: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    put-scripts-instances-instance-id: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    put-scripts-instances-instance-id-data: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    post-scripts-instances-instance-id-disable: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    post-scripts-instances-instance-id-enable: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    get-scripts-inventory: "table<config: any, data: record<description: string, name: string, scriptType: string, shortDescription: string>, eventPattern: any, scriptId: string, scriptLocalizationDetails: list<record>, scriptName: string, visibility: string>"
    get-scripts-inventory-parsed: "table<config: any, data: record<description: string, name: string, scriptType: string, shortDescription: string>, eventPattern: any, scriptId: string, scriptLocalizationDetails: list<record>, scriptName: string, visibility: string>"
    get-scripts-inventory-parsed-script-id: "record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>"
    get-subscriptions: "table<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>"
    get-subscriptions-subscription-id: "record<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>"
    get-subscriptions-subscription-id-channel-prices: "record<smsPerMessage: int, voicePerMinute: int>"
    get-subscriptions-subscription-id-features: "table<name: string, type: int, value: string>"
    get-subscriptions-subscription-id-prepaid-balance: "record<balance: int, latestTopUp: string, pendingTransaction: bool>"
    get-subscriptions-subscription-id-prepaid-settings: "record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>"
    put-subscriptions-subscription-id-prepaid-settings: "record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>"
    get-subscriptions-subscription-id-prepaid-transactions: "table<autoTopUpId: string, created: string, createdBy: string, credits: int, currency: string, modified: string, packageCode: string, status: string, statusCode: int, subscriptionId: string, transactionId: string>"
    put-subscriptions-subscription-id-profile: "record<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>"
    get-subscriptions-subscription-id-teams: "table<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>"
    get-subscriptions-subscription-id-user-licenses: "record<currentUsers: int, isFree: bool, isTrial: bool, licensedUsers: int, planCode: string>"
    get-teams: "table<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>"
    get-teams-team-id: "record<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>"
    get-teams-team-id-alert-reports: "list<record>"
    get-teams-team-id-alert-reports-file-name: "binary"
    get-teams-team-id-alert-settings: "record<filterAction: int, filterMode: int, optOutMode: int, persistentNotificicationMode: int, responseMode: int, responseTime: int>"
    post-teams-team-id-alert-settings: "record<filterAction: int, filterMode: int, optOutMode: int, persistentNotificicationMode: int, responseMode: int, responseTime: int>"
    get-teams-team-id-duty-reports: "list<record>"
    get-teams-team-id-duty-reports-file-name: "binary"
    get-teams-team-id-dutysummary: "record<dutyAssistEnabled: bool, dutySummaries: table<dutyEnd: string, dutyId: string, dutyStart: string>>"
    get-teams-team-id-event-sources: "table<address: string, groupId: string, lastEventRaised: string, subscriptionId: string, teamId: string, type: int>"
    get-teams-team-id-memberships: "table<id: string, isInvite: bool, mail: string, name: string, roleId: string>"
    post-teams-team-id-memberships: "table<errorCode: int, errorMessage: string, invitedUser: record<id: string, isInvite: bool, mail: string, name: string, roleId: string>, success: bool>"
    post-teams-team-id-memberships-resend-invite-mail: "string"
    delete-teams-team-id-memberships-user-id: "string"
    put-teams-team-id-memberships-user-id: "record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>"
    put-teams-team-id-profile: "record<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>"
    get-teams-team-id-schedules: "table<end: string, id: string, options: int, start: string, userId: string>"
    post-teams-team-id-schedules: "record<end: string, id: string, options: int, start: string, userId: string>"
    post-teams-team-id-schedules-delete-range: "table<end: string, id: string, options: int, start: string, userId: string>"
    post-teams-team-id-schedules-multiple: "table<end: string, id: string, options: int, start: string, userId: string>"
    get-teams-team-id-schedules-schedule-id: "record<end: string, id: string, options: int, start: string, userId: string>"
    get-teams-team-id-setup-progress: "record<completedSteps: list<string>, teamId: string, timestamp: string>"
    get-users: "table<colorIndex: int, contactAddresses: list<record>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>"
    get-users-user-id: "record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>"
    post-users-user-id-check-permissions: "record<content: string, contentDisposition: string, contentEncoding: string, contentType: string, lastModified: string, name: string>"
    get-users-user-id-duty-status: "record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>"
    get-users-user-id-image: "record<content: string, contentDisposition: string, contentEncoding: string, contentType: string, lastModified: string, name: string>"
    put-users-user-id-profile: "record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>"
    post-users-user-id-punch-in: "record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>"
    post-users-user-id-punch-in-as-manager: "record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>"
    post-users-user-id-punch-out: "record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>"
    get-users-user-id-setup-progress: "record<completedSteps: list<string>, timestamp: string, userId: string>"
    get-webhooks: "table<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>"
    post-webhooks: "string"
    get-webhook-by-id: "string"
    put-webhooks-webhook-id: "record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>"
    post-webhooks-webhook-id-disable: "record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>"
    post-webhooks-webhook-id-enable: "record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-alerts" "post-alerts-acknowledge-all" "post-alerts-acknowledge-multiple" "post-alerts-close-all" "post-alerts-close-multiple" "post-alerts-paged" "get-alerts-report" "post-alerts-undo-acknowledge-multiple" "post-alerts-undo-close-multiple" "get-alerts-alert-id" "post-alerts-alert-id-acknowledge" "post-alerts-alert-id-annotate" "get-alerts-alert-id-annotations" "get-alerts-alert-id-attachments" "get-alerts-alert-id-attachments-attachment-id" "post-alerts-alert-id-close" "get-alerts-alert-id-notifications" "get-alerts-alert-id-overview" "post-alerts-alert-id-undo-acknowledge" "post-alerts-alert-id-undo-close" "get-categories-images" "get-categories-team-id" "post-categories-team-id" "get-categories-team-id-metrics" "delete-categories-team-id-category-id" "get-categories-team-id-category-id" "put-categories-team-id-category-id" "get-categories-team-id-category-id-metrics" "get-categories-team-id-category-id-subscriptions" "post-categories-team-id-category-id-subscriptions" "post-events-paged" "get-events-event-id-overview" "get-events-event-id-parameters" "get-prepaid-balance" "get-prepaid-settings" "put-prepaid-settings" "get-prepaid-transactions" "get-scripts-instances" "post-scripts-instances" "delete-scripts-instances-instance-id" "get-scripts-instances-instance-id" "put-scripts-instances-instance-id" "put-scripts-instances-instance-id-data" "post-scripts-instances-instance-id-disable" "post-scripts-instances-instance-id-enable" "get-scripts-inventory" "get-scripts-inventory-parsed" "get-scripts-inventory-parsed-script-id" "get-subscriptions" "get-subscriptions-subscription-id" "get-subscriptions-subscription-id-channel-prices" "get-subscriptions-subscription-id-features" "get-subscriptions-subscription-id-prepaid-balance" "get-subscriptions-subscription-id-prepaid-settings" "put-subscriptions-subscription-id-prepaid-settings" "get-subscriptions-subscription-id-prepaid-transactions" "put-subscriptions-subscription-id-profile" "get-subscriptions-subscription-id-teams" "get-subscriptions-subscription-id-user-licenses" "get-teams" "get-teams-team-id" "get-teams-team-id-alert-reports" "get-teams-team-id-alert-reports-file-name" "get-teams-team-id-alert-settings" "post-teams-team-id-alert-settings" "get-teams-team-id-duty-reports" "get-teams-team-id-duty-reports-file-name" "get-teams-team-id-dutysummary" "get-teams-team-id-event-sources" "get-teams-team-id-memberships" "post-teams-team-id-memberships" "post-teams-team-id-memberships-resend-invite-mail" "delete-teams-team-id-memberships-user-id" "put-teams-team-id-memberships-user-id" "put-teams-team-id-profile" "get-teams-team-id-schedules" "post-teams-team-id-schedules" "post-teams-team-id-schedules-delete-range" "post-teams-team-id-schedules-multiple" "delete-teams-team-id-schedules-duty-id" "get-teams-team-id-schedules-schedule-id" "get-teams-team-id-setup-progress" "get-users" "get-users-user-id" "put-users-user-id-change-password" "post-users-user-id-check-permissions" "get-users-user-id-duty-status" "get-users-user-id-image" "post-users-user-id-image" "put-users-user-id-profile" "post-users-user-id-punch-in" "post-users-user-id-punch-in-as-manager" "post-users-user-id-punch-out" "get-users-user-id-setup-progress" "get-webhooks" "post-webhooks" "delete-webhooks-webhook-id" "get-webhook-by-id" "put-webhooks-webhook-id" "post-webhooks-webhook-id-disable" "post-webhooks-webhook-id-enable" "commands"] | sort) } | get name | first)
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

# Trigger Alert
#
# POST /alerts
# Returns: record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "post-alerts" [
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
  --attachments: list # nullable — item shape: {content?: string, contentType?: string, encoding?: "0"|"1", id?: string, name?: string}
  --category: string # nullable
  --external-id: string # nullable
  --flags: int # format: int32
  --parameters: list # nullable — item shape: {name?: string, order?: int, type?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"100", value?: string}
  --severity: int@severity-completer # format: int32
  --text: string # nullable
  --title: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts"
    body: {content_type: "application/json", kind: json, fields: [{name: attachments, var: attachments}, {name: category, var: category}, {name: externalId, var: external_id}, {name: flags, var: flags}, {name: parameters, var: parameters}, {name: severity, var: severity}, {name: text, var: text}, {name: title, var: title}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: bearer
  } {
    attachments: $attachments, category: $category, external_id: $external_id, flags: $flags, parameters: $parameters, severity: $severity, text: $text, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Confirms all visible alerts
#
# POST /alerts/acknowledgeAll
export def "post-alerts-acknowledge-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # User ID of the user to be used to acknowledge the alarms.
  --category-ids: list<string> # nullable
  --max-date: string # nullable, format: date-time
  --min-date: string # nullable, format: date-time
  --scope: int@scope-completer # format: int32
  --team-ids: list<string> # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/acknowledgeAll"
    query: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryIds, var: category_ids}, {name: maxDate, var: max_date}, {name: minDate, var: min_date}, {name: scope, var: scope}, {name: teamIds, var: team_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, category_ids: $category_ids, max_date: $max_date, min_date: $min_date, scope: $scope, team_ids: $team_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowlegde multiple alerts
#
# POST /alerts/acknowledgeMultiple
export def "post-alerts-acknowledge-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-ids: list<string> # nullable
  --description: string # nullable
  --user-id: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/acknowledgeMultiple"
    body: {content_type: "application/json", kind: json, fields: [{name: alertIds, var: alert_ids}, {name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    alert_ids: $alert_ids, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close all acknowledged alerts.
#
# POST /alerts/closeAll
export def "post-alerts-close-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # User ID of the user to be used to close the alarms.
  --category-ids: list<string> # nullable
  --max-date: string # nullable, format: date-time
  --min-date: string # nullable, format: date-time
  --scope: int@scope-completer # format: int32
  --team-ids: list<string> # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/closeAll"
    query: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryIds, var: category_ids}, {name: maxDate, var: max_date}, {name: minDate, var: min_date}, {name: scope, var: scope}, {name: teamIds, var: team_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, category_ids: $category_ids, max_date: $max_date, min_date: $min_date, scope: $scope, team_ids: $team_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close multiple alerts
#
# POST /alerts/closeMultiple
export def "post-alerts-close-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-ids: list<string> # nullable
  --description: string # nullable
  --user-id: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/closeMultiple"
    body: {content_type: "application/json", kind: json, fields: [{name: alertIds, var: alert_ids}, {name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    alert_ids: $alert_ids, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets alerts paged
#
# POST /alerts/paged
# Returns: record<continuationToken: record<nextPartitionKey: string, nextRowKey: string, nextTableName: string>, hasMore: bool, results: table<alertDeliveryStatus: record, annotations: list, categoryId: string, eventId: string, flags: int, historyDetailed: record, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>>
export def "post-alerts-paged" [
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
  --max-results: int # Defines the limit of retrieved alert details per request. 1 to 100 are allowed per request. Number of alerts could be less if filtered but at least 1. (format: int32)
  --user-id: string # User ID of the user you want to get alerts for.
  --alert-ids: list<string> # nullable
  --alerts-after-id: string # nullable
  --category-ids: list<string> # nullable
  --continuation-token: record # shape: {nextPartitionKey?: string, nextRowKey?: string, nextTableName?: string}
  --max-creation-date: string # nullable, format: date-time
  --min-creation-date: string # nullable, format: date-time
  --modified-since: string # nullable, format: date-time
  --show-personal-hidden-categories: oneof<nothing, bool>
  --status-codes: int@status-codes-completer # format: int32
  --team-id: string # nullable
  --text-to-search: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/paged"
    query: [{name: maxResults, var: max_results}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alertIds, var: alert_ids}, {name: alertsAfterId, var: alerts_after_id}, {name: categoryIds, var: category_ids}, {name: continuationToken, var: continuation_token}, {name: maxCreationDate, var: max_creation_date}, {name: minCreationDate, var: min_creation_date}, {name: modifiedSince, var: modified_since}, {name: showPersonalHiddenCategories, var: show_personal_hidden_categories}, {name: statusCodes, var: status_codes}, {name: teamId, var: team_id}, {name: textToSearch, var: text_to_search}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    max_results: $max_results, user_id: $user_id, alert_ids: $alert_ids, alerts_after_id: $alerts_after_id, category_ids: $category_ids, continuation_token: $continuation_token, max_creation_date: $max_creation_date, min_creation_date: $min_creation_date, modified_since: $modified_since, show_personal_hidden_categories: $show_personal_hidden_categories, status_codes: $status_codes, team_id: $team_id, text_to_search: $text_to_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Alert Report
#
# GET /alerts/report
# Returns: record<last24Hours: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, subscriptionId: string, teamCurrentDuty: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, teamId: string, teamLastDuty: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>, userId: string, userLastDutyChange: record<acked: int, closed: int, end: string, lastModified: string, start: string, unhandled: int>>
export def "get-alerts-report" [
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
  --user-id: string # User ID of the user for whom you want a report.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/report"
    query: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queue undo of multiple acknowledgments.
#
# POST /alerts/undoAcknowledgeMultiple
export def "post-alerts-undo-acknowledge-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-ids: list<string> # nullable
  --description: string # nullable
  --user-id: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/undoAcknowledgeMultiple"
    body: {content_type: "application/json", kind: json, fields: [{name: alertIds, var: alert_ids}, {name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    alert_ids: $alert_ids, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Withdraw closure of multiple alerts
#
# POST /alerts/undoCloseMultiple
export def "post-alerts-undo-close-multiple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-ids: list<string> # nullable
  --description: string # nullable
  --user-id: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/alerts/undoCloseMultiple"
    body: {content_type: "application/json", kind: json, fields: [{name: alertIds, var: alert_ids}, {name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    alert_ids: $alert_ids, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Alert
#
# GET /alerts/{alertId}
# Returns: record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "get-alerts-alert-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alertId}"
    path_params: [{name: alertId, var: alert_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Acknowledge an alert
#
# POST /alerts/{alertId}/acknowledge
# Returns: record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "post-alerts-alert-id-acknowledge" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/{alertId}/acknowledge"
    path_params: [{name: alertId, var: alert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Annotate Alert
#
# POST /alerts/{alertId}/annotate
# Returns: record<annotationType: int, id: string, text: string, timestamp: string, userId: string>
export def "post-alerts-alert-id-annotate" [
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
  --accept: string@accept-completer # Response content type
  --annotation-type: int # format: int32
  --id: string # nullable
  --text: string # nullable
  --timestamp: string # format: date-time
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/{alertId}/annotate"
    path_params: [{name: alertId, var: alert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotationType, var: annotation_type}, {name: id, var: id}, {name: text, var: text}, {name: timestamp, var: timestamp}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, annotation_type: $annotation_type, id: $id, text: $text, timestamp: $timestamp, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get annotations of an alert
#
# GET /alerts/{alertId}/annotations
# Returns: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>
export def "get-alerts-alert-id-annotations" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alertId}/annotations"
    path_params: [{name: alertId, var: alert_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get attachments of an alert
#
# GET /alerts/{alertId}/attachments
# Returns: table<contentType: string, id: string, name: string>
export def "get-alerts-alert-id-attachments" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alertId}/attachments"
    path_params: [{name: alertId, var: alert_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a specified attachment of a specified alert.
#
# GET /alerts/{alertId}/attachments/{attachmentId}
# Returns: binary
export def "get-alerts-alert-id-attachments-attachment-id" [
  alert_id: string
  attachment_id: string
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
  --width: int # Optional parameter defining the wanted width of the picture that is retrieved. (format: int32)
  --height: int # Optional parameter defining the wanted height of the picture that is retrieved. (format: int32)
  --scale: oneof<nothing, bool> # Optional parameter defining whether it's wanted to scale the retrieved image. Default is set to true. (default: true)
]: nothing -> any {
  http-request {
    method: get
    path: "/alerts/{alertId}/attachments/{attachmentId}"
    path_params: [{name: alertId, var: alert_id}, {name: attachmentId, var: attachment_id}]
    query: [{name: width, var: width}, {name: height, var: height}, {name: scale, var: scale}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    alert_id: $alert_id, attachment_id: $attachment_id, width: $width, height: $height, scale: $scale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Close an alert
#
# POST /alerts/{alertId}/close
# Returns: record<annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, attachments: table<content: string, contentType: string, encoding: int, id: string, name: string>, category: string, categoryId: string, eventId: string, eventSourceId: string, eventSourceType: int, flags: int, history: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, parameters: table<name: string, order: int, type: int, value: string>, severity: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "post-alerts-alert-id-close" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/{alertId}/close"
    path_params: [{name: alertId, var: alert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get alert notifications
#
# GET /alerts/{alertId}/notifications
# Returns: table<address: string, channelType: int, deviceName: string, lastUpdate: string, messageStatus: int, userId: string, userStatus: int>
export def "get-alerts-alert-id-notifications" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alertId}/notifications"
    path_params: [{name: alertId, var: alert_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get an overview alert.
#
# GET /alerts/{alertId}/overview
# Returns: record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "get-alerts-alert-id-overview" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alertId}/overview"
    path_params: [{name: alertId, var: alert_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Undo the acknowledgement of an alert.
#
# POST /alerts/{alertId}/undoAcknowledge
# Returns: record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "post-alerts-alert-id-undo-acknowledge" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/{alertId}/undoAcknowledge"
    path_params: [{name: alertId, var: alert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Undo the closure of an alert.
#
# POST /alerts/{alertId}/undoClose
# Returns: record<alertDeliveryStatus: record<statusCode: int, users: list<record>>, annotations: table<annotationType: int, id: string, text: string, timestamp: string, userId: string>, categoryId: string, eventId: string, flags: int, historyDetailed: record<acknowledged: string, acknowledgedgements: list<string>, closed: string, closedBy: string, created: string, historyEntries: list<record>>, id: string, lastModified: string, requiredAcknowledgements: int, status: int, subscriptionId: string, teamId: string, text: string, title: string>
export def "post-alerts-alert-id-undo-close" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts/{alertId}/undoClose"
    path_params: [{name: alertId, var: alert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, description: $description, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the names of all alert category images. You can get the image by going to account.signl4.com/images/alerts/categoryImageName.svg
#
# GET /categories/images
# Returns: list<string>
export def "get-categories-images" [
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
    path: "/categories/images"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all categories
#
# GET /categories/{teamId}
# Returns: table<augmentations: list<record>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>
export def "get-categories-team-id" [
  team_id: string
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
    path: "/categories/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a new category
#
# POST /categories/{teamId}
# Returns: record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>
export def "post-categories-team-id" [
  team_id: string
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
  --augmentations: list # nullable — item shape: {enabled?: bool, name?: string, type?: "0"|"1"|"2"|"3", value?: string}
  --color: string # nullable
  --id: string # nullable
  --image-name: string # nullable
  --keyword-matching: int@keyword-matching-completer # format: int32
  --keywords: list<string> # nullable
  --last-match: string # nullable, format: date-time
  --name: string # nullable
  --options: int@options-completer # format: int32
  --order: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: augmentations, var: augmentations}, {name: color, var: color}, {name: id, var: id}, {name: imageName, var: image_name}, {name: keywordMatching, var: keyword_matching}, {name: keywords, var: keywords}, {name: lastMatch, var: last_match}, {name: name, var: name}, {name: options, var: options}, {name: order, var: order}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: bearer
  } {
    team_id: $team_id, augmentations: $augmentations, color: $color, id: $id, image_name: $image_name, keyword_matching: $keyword_matching, keywords: $keywords, last_match: $last_match, name: $name, options: $options, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for all categories
#
# GET /categories/{teamId}/metrics
# Returns: table<categoryId: string, last24Hours: int, lastAlert: string, subscriberCount: int>
export def "get-categories-team-id-metrics" [
  team_id: string
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
    path: "/categories/{teamId}/metrics"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing category
#
# DELETE /categories/{teamId}/{categoryId}
export def "delete-categories-team-id-category-id" [
  team_id: string
  category_id: string
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
    path: "/categories/{teamId}/{categoryId}"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific category
#
# GET /categories/{teamId}/{categoryId}
# Returns: record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>
export def "get-categories-team-id-category-id" [
  team_id: string
  category_id: string
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
    path: "/categories/{teamId}/{categoryId}"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an existing category
#
# PUT /categories/{teamId}/{categoryId}
# Returns: record<augmentations: table<enabled: bool, name: string, type: int, value: string>, color: string, id: string, imageName: string, isDefault: bool, keywordMatching: int, keywords: list<string>, lastMatch: string, name: string, options: int, order: int>
export def "put-categories-team-id-category-id" [
  team_id: string
  category_id: string
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
  --augmentations: list # nullable — item shape: {enabled?: bool, name?: string, type?: "0"|"1"|"2"|"3", value?: string}
  --color: string # nullable
  --id: string # nullable
  --image-name: string # nullable
  --keyword-matching: int@keyword-matching-completer # format: int32
  --keywords: list<string> # nullable
  --last-match: string # nullable, format: date-time
  --name: string # nullable
  --options: int@options-completer # format: int32
  --order: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/categories/{teamId}/{categoryId}"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: augmentations, var: augmentations}, {name: color, var: color}, {name: id, var: id}, {name: imageName, var: image_name}, {name: keywordMatching, var: keyword_matching}, {name: keywords, var: keywords}, {name: lastMatch, var: last_match}, {name: name, var: name}, {name: options, var: options}, {name: order, var: order}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id, augmentations: $augmentations, color: $color, id: $id, image_name: $image_name, keyword_matching: $keyword_matching, keywords: $keywords, last_match: $last_match, name: $name, options: $options, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for a specific category
#
# GET /categories/{teamId}/{categoryId}/metrics
# Returns: record<categoryId: string, last24Hours: int, lastAlert: string, subscriberCount: int>
export def "get-categories-team-id-category-id-metrics" [
  team_id: string
  category_id: string
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
    path: "/categories/{teamId}/{categoryId}/metrics"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get category subscriptions
#
# GET /categories/{teamId}/{categoryId}/subscriptions
# Returns: table<status: int, userId: string>
export def "get-categories-team-id-category-id-subscriptions" [
  team_id: string
  category_id: string
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
    path: "/categories/{teamId}/{categoryId}/subscriptions"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set category subscriptions
#
# POST /categories/{teamId}/{categoryId}/subscriptions
# Returns: table<status: int, userId: string>
export def "post-categories-team-id-category-id-subscriptions" [
  team_id: string
  category_id: string
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories/{teamId}/{categoryId}/subscriptions"
    path_params: [{name: teamId, var: team_id}, {name: categoryId, var: category_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, category_id: $category_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get overview event paged.
#
# POST /events/paged
# Returns: record<continuationToken: record<nextPartitionKey: string, nextRowKey: string, nextTableName: string>, hasMore: bool, results: table<acknowledgedAlerts: list, alertId: string, categoryId: string, closedAlerts: list, creationTime: string, eventSourceType: int, eventStatus: int, id: string, lastModified: string, severity: int, teamId: string, text: string, title: string>>
export def "post-events-paged" [
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
  --max-results: int # Defines the limit of retrieved alert details per request. 1 to 100 are allowed per request. Number of alerts could be less if filtered but at least 1. (format: int32)
  --continuation-token: record # shape: {nextPartitionKey?: string, nextRowKey?: string, nextTableName?: string}
  --event-status-code: int@event-status-code-completer # format: int32
  --max-creation-date: string # nullable, format: date-time
  --min-creation-date: string # nullable, format: date-time
  --modified-since: string # nullable, format: date-time
  --team-id: string # nullable
  --text-to-search: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/events/paged"
    query: [{name: maxResults, var: max_results}]
    body: {content_type: "application/json", kind: json, fields: [{name: continuationToken, var: continuation_token}, {name: eventStatusCode, var: event_status_code}, {name: maxCreationDate, var: max_creation_date}, {name: minCreationDate, var: min_creation_date}, {name: modifiedSince, var: modified_since}, {name: teamId, var: team_id}, {name: textToSearch, var: text_to_search}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    max_results: $max_results, continuation_token: $continuation_token, event_status_code: $event_status_code, max_creation_date: $max_creation_date, min_creation_date: $min_creation_date, modified_since: $modified_since, team_id: $team_id, text_to_search: $text_to_search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get overview event
#
# GET /events/{eventId}/overview
# Returns: record<acknowledgedAlerts: list<string>, alertId: string, categoryId: string, closedAlerts: list<string>, creationTime: string, eventSourceType: int, eventStatus: int, id: string, lastModified: string, severity: int, teamId: string, text: string, title: string>
export def "get-events-event-id-overview" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{eventId}/overview"
    path_params: [{name: eventId, var: event_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get event parameters
#
# GET /events/{eventId}/parameters
# Returns: table<name: string, order: int, type: int, value: string>
export def "get-events-event-id-parameters" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{eventId}/parameters"
    path_params: [{name: eventId, var: event_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get your subscription's current prepaid balance.
#
# GET /prepaid/balance
# Returns: record<balance: int, latestTopUp: string, pendingTransaction: bool>
export def "get-prepaid-balance" [
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
    path: "/prepaid/balance"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get your subscription's current prepaid settings.
#
# GET /prepaid/settings
# Returns: record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>
export def "get-prepaid-settings" [
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
    path: "/prepaid/settings"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update your subscription's current prepaid settings.
#
# PUT /prepaid/settings
# Returns: record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>
export def "put-prepaid-settings" [
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
  --top-up-amount: int # format: int32
  --top-up-enabled: oneof<nothing, bool>
  --top-up-limit: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/prepaid/settings"
    body: {content_type: "application/json", kind: json, fields: [{name: topUpAmount, var: top_up_amount}, {name: topUpEnabled, var: top_up_enabled}, {name: topUpLimit, var: top_up_limit}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    top_up_amount: $top_up_amount, top_up_enabled: $top_up_enabled, top_up_limit: $top_up_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get your subscription's prepaid transactions.
#
# GET /prepaid/transactions
# Returns: table<autoTopUpId: string, created: string, createdBy: string, credits: int, currency: string, modified: string, packageCode: string, status: string, statusCode: int, subscriptionId: string, transactionId: string>
export def "get-prepaid-transactions" [
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
    path: "/prepaid/transactions"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all script instances of the SIGNL4 team
#
# GET /scripts/instances
# Returns: table<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "get-scripts-instances" [
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
  --team-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scripts/instances"
    query: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new script instance in the in the SIGNL4 team.
#
# POST /scripts/instances
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "post-scripts-instances" [
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
  --config: any # nullable
  --custom-script-description: string # nullable
  --custom-script-name: string # nullable
  --enabled: oneof<nothing, bool>
  --event-pattern: any # nullable
  --instance-id: string # nullable
  --last-modified: string # nullable, format: date-time
  --runtime-information: record # shape: {status?: "0"|"1"|"2"|"3"|"-1", statusMessage?: string}
  --script-id: string # nullable
  --script-name: string # nullable
  --subscription-id: string # nullable
  --team-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/scripts/instances"
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: customScriptDescription, var: custom_script_description}, {name: customScriptName, var: custom_script_name}, {name: enabled, var: enabled}, {name: eventPattern, var: event_pattern}, {name: instanceId, var: instance_id}, {name: lastModified, var: last_modified}, {name: runtimeInformation, var: runtime_information}, {name: scriptId, var: script_id}, {name: scriptName, var: script_name}, {name: subscriptionId, var: subscription_id}, {name: teamId, var: team_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 201]
    auth: bearer
  } {
    config: $config, custom_script_description: $custom_script_description, custom_script_name: $custom_script_name, enabled: $enabled, event_pattern: $event_pattern, instance_id: $instance_id, last_modified: $last_modified, runtime_information: $runtime_information, script_id: $script_id, script_name: $script_name, subscription_id: $subscription_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a script instance.
#
# DELETE /scripts/instances/{instanceId}
export def "delete-scripts-instances-instance-id" [
  instance_id: string
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
    path: "/scripts/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all information about a given script instance which includes its runtime status.
#
# GET /scripts/instances/{instanceId}
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "get-scripts-instances-instance-id" [
  instance_id: string
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
    path: "/scripts/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a given script instance, typically used for updating the configuration of a script.
#
# PUT /scripts/instances/{instanceId}
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "put-scripts-instances-instance-id" [
  instance_id: string
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
  --config: any # nullable
  --custom-script-description: string # nullable
  --custom-script-name: string # nullable
  --enabled: oneof<nothing, bool>
  --event-pattern: any # nullable
  --body-instance-id: string # nullable (spec name: instanceId)
  --last-modified: string # nullable, format: date-time
  --runtime-information: record # shape: {status?: "0"|"1"|"2"|"3"|"-1", statusMessage?: string}
  --script-id: string # nullable
  --script-name: string # nullable
  --subscription-id: string # nullable
  --team-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/scripts/instances/{instanceId}"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: customScriptDescription, var: custom_script_description}, {name: customScriptName, var: custom_script_name}, {name: enabled, var: enabled}, {name: eventPattern, var: event_pattern}, {name: instanceId, var: body_instance_id}, {name: lastModified, var: last_modified}, {name: runtimeInformation, var: runtime_information}, {name: scriptId, var: script_id}, {name: scriptName, var: script_name}, {name: subscriptionId, var: subscription_id}, {name: teamId, var: team_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, config: $config, custom_script_description: $custom_script_description, custom_script_name: $custom_script_name, enabled: $enabled, event_pattern: $event_pattern, body_instance_id: $body_instance_id, last_modified: $last_modified, runtime_information: $runtime_information, script_id: $script_id, script_name: $script_name, subscription_id: $subscription_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates custom data of a given script instance which includes its display name.
#
# PUT /scripts/instances/{instanceId}/data
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "put-scripts-instances-instance-id-data" [
  instance_id: string
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
  --custom-script-description: string # nullable
  --custom-script-name: string # nullable
  --body-instance-id: string # nullable (spec name: instanceId)
  --script-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/scripts/instances/{instanceId}/data"
    path_params: [{name: instanceId, var: instance_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: customScriptDescription, var: custom_script_description}, {name: customScriptName, var: custom_script_name}, {name: instanceId, var: body_instance_id}, {name: scriptId, var: script_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, custom_script_description: $custom_script_description, custom_script_name: $custom_script_name, body_instance_id: $body_instance_id, script_id: $script_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disables a given script instance.
#
# POST /scripts/instances/{instanceId}/disable
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "post-scripts-instances-instance-id-disable" [
  instance_id: string
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
    method: post
    path: "/scripts/instances/{instanceId}/disable"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enables a script instance.
#
# POST /scripts/instances/{instanceId}/enable
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "post-scripts-instances-instance-id-enable" [
  instance_id: string
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
    method: post
    path: "/scripts/instances/{instanceId}/enable"
    path_params: [{name: instanceId, var: instance_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all available inventory scripts which can be added to a SIGNL4 subscription.
#
# GET /scripts/inventory
# Returns: table<config: any, data: record<description: string, name: string, scriptType: string, shortDescription: string>, eventPattern: any, scriptId: string, scriptLocalizationDetails: list<record>, scriptName: string, visibility: string>
export def "get-scripts-inventory" [
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
    path: "/scripts/inventory"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all inventory scripts.
#
# GET /scripts/inventory/parsed
# Returns: table<config: any, data: record<description: string, name: string, scriptType: string, shortDescription: string>, eventPattern: any, scriptId: string, scriptLocalizationDetails: list<record>, scriptName: string, visibility: string>
export def "get-scripts-inventory-parsed" [
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
  --language: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scripts/inventory/parsed"
    query: [{name: language, var: language}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns an inventory script by its id.
#
# GET /scripts/inventory/parsed/{scriptId}
# Returns: record<config: any, customScriptDescription: string, customScriptName: string, enabled: bool, eventPattern: any, instanceId: string, lastModified: string, runtimeInformation: record<status: int, statusMessage: string>, scriptId: string, scriptName: string, subscriptionId: string, teamId: string>
export def "get-scripts-inventory-parsed-script-id" [
  script_id: string
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
  --language: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scripts/inventory/parsed/{scriptId}"
    path_params: [{name: scriptId, var: script_id}]
    query: [{name: language, var: language}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    script_id: $script_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get infos of all available/managed subscriptions.
#
# GET /subscriptions
# Returns: table<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>
export def "get-subscriptions" [
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
    path: "/subscriptions"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get infos of a specific subscription.
#
# GET /subscriptions/{subscriptionId}
# Returns: record<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>
export def "get-subscriptions-subscription-id" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the subscription's channel price information.
#
# GET /subscriptions/{subscriptionId}/channelPrices
# Returns: record<smsPerMessage: int, voicePerMinute: int>
export def "get-subscriptions-subscription-id-channel-prices" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/channelPrices"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns the features of a specified subscription.
#
# GET /subscriptions/{subscriptionId}/features
# Returns: table<name: string, type: int, value: string>
export def "get-subscriptions-subscription-id-features" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/features"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a subscription's current prepaid balance.
#
# GET /subscriptions/{subscriptionId}/prepaidBalance
# Returns: record<balance: int, latestTopUp: string, pendingTransaction: bool>
export def "get-subscriptions-subscription-id-prepaid-balance" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/prepaidBalance"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a subscription's current prepaid settings.
#
# GET /subscriptions/{subscriptionId}/prepaidSettings
# Returns: record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>
export def "get-subscriptions-subscription-id-prepaid-settings" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/prepaidSettings"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a subscription's current prepaid settings.
#
# PUT /subscriptions/{subscriptionId}/prepaidSettings
# Returns: record<topUpAmount: int, topUpEnabled: bool, topUpLimit: int>
export def "put-subscriptions-subscription-id-prepaid-settings" [
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
  --accept: string@accept-completer # Response content type
  --top-up-amount: int # format: int32
  --top-up-enabled: oneof<nothing, bool>
  --top-up-limit: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/prepaidSettings"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: topUpAmount, var: top_up_amount}, {name: topUpEnabled, var: top_up_enabled}, {name: topUpLimit, var: top_up_limit}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, top_up_amount: $top_up_amount, top_up_enabled: $top_up_enabled, top_up_limit: $top_up_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a subscription's prepaid transactions.
#
# GET /subscriptions/{subscriptionId}/prepaidTransactions
# Returns: table<autoTopUpId: string, created: string, createdBy: string, credits: int, currency: string, modified: string, packageCode: string, status: string, statusCode: int, subscriptionId: string, transactionId: string>
export def "get-subscriptions-subscription-id-prepaid-transactions" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/prepaidTransactions"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a subscriptions profile.
#
# PUT /subscriptions/{subscriptionId}/profile
# Returns: record<branchId: string, country: string, currency: string, externalAccountId: string, id: string, name: string, nextBilling: string, ownerId: string, planCode: string, planState: int, referralEnabled: bool, status: int>
export def "put-subscriptions-subscription-id-profile" [
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
  --accept: string@accept-completer # Response content type
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/profile"
    path_params: [{name: subscriptionId, var: subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get infos for all teams of the subscription.
#
# GET /subscriptions/{subscriptionId}/teams
# Returns: table<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>
export def "get-subscriptions-subscription-id-teams" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/teams"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a subscription's user licenses.
#
# GET /subscriptions/{subscriptionId}/userLicenses
# Returns: record<currentUsers: int, isFree: bool, isTrial: bool, licensedUsers: int, planCode: string>
export def "get-subscriptions-subscription-id-user-licenses" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/userLicenses"
    path_params: [{name: subscriptionId, var: subscription_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get infos of all teams.
#
# GET /teams
# Returns: table<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>
export def "get-teams" [
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
    path: "/teams"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets infos of a specific team.
#
# GET /teams/{teamId}
# Returns: record<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>
export def "get-teams-team-id" [
  team_id: string
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
    path: "/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get information about downloadable alert reports
#
# GET /teams/{teamId}/alertReports
# Returns: list<record>
export def "get-teams-team-id-alert-reports" [
  team_id: string
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
    path: "/teams/{teamId}/alertReports"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Alert Report
#
# GET /teams/{teamId}/alertReports/{fileName}
# Returns: binary
export def "get-teams-team-id-alert-reports-file-name" [
  team_id: string
  file_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/teams/{teamId}/alertReports/{fileName}"
    path_params: [{name: teamId, var: team_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets alert settings of a specific team.
#
# GET /teams/{teamId}/alertSettings
# Returns: record<filterAction: int, filterMode: int, optOutMode: int, persistentNotificicationMode: int, responseMode: int, responseTime: int>
export def "get-teams-team-id-alert-settings" [
  team_id: string
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
    path: "/teams/{teamId}/alertSettings"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sets alert settings of a specific team.
#
# POST /teams/{teamId}/alertSettings
# Returns: record<filterAction: int, filterMode: int, optOutMode: int, persistentNotificicationMode: int, responseMode: int, responseTime: int>
export def "post-teams-team-id-alert-settings" [
  team_id: string
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
  --filter-action: int@filter-action-completer # format: int32
  --filter-mode: int@filter-mode-completer # format: int32
  --opt-out-mode: int@opt-out-mode-completer # format: int32
  --persistent-notificication-mode: int@persistent-notificication-mode-completer # format: int32
  --response-mode: int@response-mode-completer # format: int32
  --response-time: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/alertSettings"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filterAction, var: filter_action}, {name: filterMode, var: filter_mode}, {name: optOutMode, var: opt_out_mode}, {name: persistentNotificicationMode, var: persistent_notificication_mode}, {name: responseMode, var: response_mode}, {name: responseTime, var: response_time}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, filter_action: $filter_action, filter_mode: $filter_mode, opt_out_mode: $opt_out_mode, persistent_notificication_mode: $persistent_notificication_mode, response_mode: $response_mode, response_time: $response_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Information about downloadable reports
#
# GET /teams/{teamId}/dutyReports
# Returns: list<record>
export def "get-teams-team-id-duty-reports" [
  team_id: string
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
    path: "/teams/{teamId}/dutyReports"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Download duty report with a specific fileName
#
# GET /teams/{teamId}/dutyReports/{fileName}
# Returns: binary
export def "get-teams-team-id-duty-reports-file-name" [
  team_id: string
  file_name: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/teams/{teamId}/dutyReports/{fileName}"
    path_params: [{name: teamId, var: team_id}, {name: fileName, var: file_name}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, file_name: $file_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get duty assistant info for a team
#
# GET /teams/{teamId}/dutysummary
# Returns: record<dutyAssistEnabled: bool, dutySummaries: table<dutyEnd: string, dutyId: string, dutyStart: string>>
export def "get-teams-team-id-dutysummary" [
  team_id: string
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
  --last-two-duties: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{teamId}/dutysummary"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: lastTwoDuties, var: last_two_duties}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, last_two_duties: $last_two_duties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets event sources of a specific team.
#
# GET /teams/{teamId}/eventSources
# Returns: table<address: string, groupId: string, lastEventRaised: string, subscriptionId: string, teamId: string, type: int>
export def "get-teams-team-id-event-sources" [
  team_id: string
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
    path: "/teams/{teamId}/eventSources"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all invites of a team.
#
# GET /teams/{teamId}/memberships
# Returns: table<id: string, isInvite: bool, mail: string, name: string, roleId: string>
export def "get-teams-team-id-memberships" [
  team_id: string
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
    path: "/teams/{teamId}/memberships"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite users to a team
#
# POST /teams/{teamId}/memberships
# Returns: table<errorCode: int, errorMessage: string, invitedUser: record<id: string, isInvite: bool, mail: string, name: string, roleId: string>, success: bool>
export def "post-teams-team-id-memberships" [
  team_id: string
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
  --inviter-id: string # nullable
  --invites: list # nullable — item shape: {email?: string, roleId?: string}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/memberships"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: inviterId, var: inviter_id}, {name: invites, var: invites}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    team_id: $team_id, inviter_id: $inviter_id, invites: $invites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sends invite email again if an invite exists
#
# POST /teams/{teamId}/memberships/resendInviteMail
# Returns: string
export def "post-teams-team-id-memberships-resend-invite-mail" [
  team_id: string
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
  --inviter-id: string # nullable
  --user-mail: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/memberships/resendInviteMail"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: inviterId, var: inviter_id}, {name: userMail, var: user_mail}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, inviter_id: $inviter_id, user_mail: $user_mail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes a user or invitation from a team, and may delete the user if he is not in any team.
#
# DELETE /teams/{teamId}/memberships/{userId}
# Returns: string
export def "delete-teams-team-id-memberships-user-id" [
  team_id: string
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
  --accept: string@accept-completer # Response content type
  --requester-user-id: string # User ID of user which will remove the other user.
]: nothing -> any {
  http-request {
    method: delete
    path: "/teams/{teamId}/memberships/{userId}"
    path_params: [{name: teamId, var: team_id}, {name: userId, var: user_id}]
    query: [{name: requesterUserId, var: requester_user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    team_id: $team_id, user_id: $user_id, requester_user_id: $requester_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user's team membership.
#
# PUT /teams/{teamId}/memberships/{userId}
# Returns: record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>
export def "put-teams-team-id-memberships-user-id" [
  team_id: string
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
  --accept: string@accept-completer # Response content type
  --requester-user-id: string # User ID of user which you want to change role with. This must be provided when using an api key. This user must have role administrator (for setting administrator role) or team administrator (for setting rights.
  --role-id: string # nullable
  --body-team-id: string # nullable (spec name: teamId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/teams/{teamId}/memberships/{userId}"
    path_params: [{name: teamId, var: team_id}, {name: userId, var: user_id}]
    query: [{name: requesterUserId, var: requester_user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: roleId, var: role_id}, {name: teamId, var: body_team_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200, 204]
    auth: bearer
  } {
    team_id: $team_id, user_id: $user_id, requester_user_id: $requester_user_id, role_id: $role_id, body_team_id: $body_team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates team profile of a team
#
# PUT /teams/{teamId}/profile
# Returns: record<id: string, memberIds: list<string>, name: string, subscriptionId: string, timezone: string>
export def "put-teams-team-id-profile" [
  team_id: string
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
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/teams/{teamId}/profile"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns information about all duties that belong to the team.
#
# GET /teams/{teamId}/schedules
# Returns: table<end: string, id: string, options: int, start: string, userId: string>
export def "get-teams-team-id-schedules" [
  team_id: string
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
  --user-id: string
  --min-date: string # format: date-time
  --limit: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{teamId}/schedules"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: UserId, var: user_id}, {name: MinDate, var: min_date}, {name: Limit, var: limit}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, user_id: $user_id, min_date: $min_date, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create/Update given duty schedule.
#
# POST /teams/{teamId}/schedules
# Returns: record<end: string, id: string, options: int, start: string, userId: string>
export def "post-teams-team-id-schedules" [
  team_id: string
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
  --end: string # format: date-time
  --id: string # nullable
  --options: int # format: int32
  --start: string # format: date-time
  --user-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/schedules"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: end, var: end}, {name: id, var: id}, {name: options, var: options}, {name: start, var: start}, {name: userId, var: user_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, end: $end, id: $id, options: $options, start: $start, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete duty schedules in range
#
# POST /teams/{teamId}/schedules/deleteRange
# Returns: table<end: string, id: string, options: int, start: string, userId: string>
export def "post-teams-team-id-schedules-delete-range" [
  team_id: string
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
  --from: string # format: date-time
  --to: string # format: date-time
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/schedules/deleteRange"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: from, var: from}, {name: to, var: to}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Save multiple schedules. It is possible to override existing schedules if you wish
#
# POST /teams/{teamId}/schedules/multiple
# Returns: table<end: string, id: string, options: int, start: string, userId: string>
export def "post-teams-team-id-schedules-multiple" [
  team_id: string
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
  --override-existing: oneof<nothing, bool> # Override or cut existing schedules if set to true.
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{teamId}/schedules/multiple"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: overrideExisting, var: override_existing}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, override_existing: $override_existing, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a specific duty.
#
# DELETE /teams/{teamId}/schedules/{dutyId}
export def "delete-teams-team-id-schedules-duty-id" [
  team_id: string
  duty_id: string
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
    path: "/teams/{teamId}/schedules/{dutyId}"
    path_params: [{name: teamId, var: team_id}, {name: dutyId, var: duty_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    team_id: $team_id, duty_id: $duty_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information of the duty schedule with the specified Id.
#
# GET /teams/{teamId}/schedules/{scheduleId}
# Returns: record<end: string, id: string, options: int, start: string, userId: string>
export def "get-teams-team-id-schedules-schedule-id" [
  team_id: string
  schedule_id: string
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
    path: "/teams/{teamId}/schedules/{scheduleId}"
    path_params: [{name: teamId, var: team_id}, {name: scheduleId, var: schedule_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, schedule_id: $schedule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets setup progress of a specific team.
#
# GET /teams/{teamId}/setupProgress
# Returns: record<completedSteps: list<string>, teamId: string, timestamp: string>
export def "get-teams-team-id-setup-progress" [
  team_id: string
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
    path: "/teams/{teamId}/setupProgress"
    path_params: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all Users
#
# GET /users
# Returns: table<colorIndex: int, contactAddresses: list<record>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get User by Id
#
# GET /users/{userId}
# Returns: record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the password of a user
#
# PUT /users/{userId}/changePassword
export def "put-users-user-id-change-password" [
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
  --current-password: string # nullable
  --new-password: string # nullable
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/changePassword"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: currentPassword, var: current_password}, {name: newPassword, var: new_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, current_password: $current_password, new_password: $new_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks if a user has the provided permission.
#
# POST /users/{userId}/checkPermissions
# Returns: record<content: string, contentDisposition: string, contentEncoding: string, contentType: string, lastModified: string, name: string>
export def "post-users-user-id-check-permissions" [
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
  --accept: string@accept-completer # Response content type
  --team-id: string
  --items: list<string> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/checkPermissions"
    path_params: [{name: userId, var: user_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, team_id: $team_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get duty status by user Id
#
# GET /users/{userId}/dutyStatus
# Returns: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>
export def "get-users-user-id-duty-status" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/dutyStatus"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /users/{userId}/image
#
# Returns: record<content: string, contentDisposition: string, contentEncoding: string, contentType: string, lastModified: string, name: string>
export def "get-users-user-id-image" [
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
  --accept: string@accept-completer # Response content type
  --height: int # format: int32
  --width: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/image"
    path_params: [{name: userId, var: user_id}]
    query: [{name: height, var: height}, {name: width, var: width}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, height: $height, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Uploaded a profile image for a specified user.
#
# POST /users/{userId}/image
export def "post-users-user-id-image" [
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
    method: post
    path: "/users/{userId}/image"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates user profile of an user
#
# PUT /users/{userId}/profile
# Returns: record<colorIndex: int, contactAddresses: table<address: string, channel: int, created: string, device: record, id: string, lastUpdated: string, options: int, userId: string>, dutyInfo: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>, id: string, isDeactivated: bool, isInvite: bool, mail: string, name: string, roleId: string, subscriptionId: string, timeZone: string, userImageLastModified: string>
export def "put-users-user-id-profile" [
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
  --accept: string@accept-completer # Response content type
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{userId}/profile"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Punch User in
#
# POST /users/{userId}/punchIn
# Returns: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>
export def "post-users-user-id-punch-in" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{userId}/punchIn"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Punch User in as Manager
#
# POST /users/{userId}/punchInAsManager
# Returns: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>
export def "post-users-user-id-punch-in-as-manager" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{userId}/punchInAsManager"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Punch User out
#
# POST /users/{userId}/punchOut
# Returns: record<lastStatusChange: string, onDuty: bool, onManagerDuty: bool, overdue: bool>
export def "post-users-user-id-punch-out" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/users/{userId}/punchOut"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets setup progress of a specific user.
#
# GET /users/{userId}/setupProgress
# Returns: record<completedSteps: list<string>, timestamp: string, userId: string>
export def "get-users-user-id-setup-progress" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/setupProgress"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Webhooks
#
# GET /webhooks
# Returns: table<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>
export def "get-webhooks" [
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
  --team-id: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: teamId, var: team_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create Webhook
#
# POST /webhooks
# Returns: string
export def "post-webhooks" [
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
  --external-address: string # nullable
  --name: string # nullable
  --team-id: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: externalAddress, var: external_address}, {name: name, var: name}, {name: teamId, var: team_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [201]
    auth: bearer
  } {
    external_address: $external_address, name: $name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete Webhook by Id
#
# DELETE /webhooks/{webhookId}
export def "delete-webhooks-webhook-id" [
  webhook_id: string
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
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Webhook by Id
#
# GET /webhooks/{webhookId}
# Returns: string
# operationId: GetWebhookById
export def "get-webhook-by-id" [
  webhook_id: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Webhook by Id
#
# PUT /webhooks/{webhookId}
# Returns: record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>
export def "put-webhooks-webhook-id" [
  webhook_id: string
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
  --external-address: string # nullable
  --name: string # nullable
  --team-id: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: externalAddress, var: external_address}, {name: name, var: name}, {name: teamId, var: team_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, external_address: $external_address, name: $name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Ability to enable a webHook.
#
# POST /webhooks/{webhookId}/disable
# Returns: record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>
export def "post-webhooks-webhook-id-disable" [
  webhook_id: string
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
    method: post
    path: "/webhooks/{webhookId}/disable"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Ability to disable a webHook.
#
# POST /webhooks/{webhookId}/enable
# Returns: record<enabled: bool, externalAddress: string, id: string, name: string, subscriptionId: string, teamId: string>
export def "post-webhooks-webhook-id-enable" [
  webhook_id: string
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
    method: post
    path: "/webhooks/{webhookId}/enable"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
