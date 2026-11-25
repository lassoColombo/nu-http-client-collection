# Auto-generated client for Zoom API v2.0.0
# Source: https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.json
# Auth: --token flag or $env.ZOOM_API_TOKEN

const CLIENT = {
  base_url: "https://api.zoom.us/v2"
  token_env_var: "ZOOM_API_TOKEN"
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

def base-url-completer [] { ["https://api.zoom.us/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def pay-mode-completer [] { ["master" "sub"] }
def action-completer [] { ["cancel"] }
def reason-completer [] { ["1" "2" "3" "4" "5" "6"] }
def option-completer [] { ["meeting_authentication" "recording_authentication"] }
def option-completer-1 [] { ["meeting_authentication" "meeting_security" "recording_authentication" "security"] }
def show-zoom-provided-numbers-completer [] { ["0" "1" "2"] }
def query-data-type-completer [] { ["archive_complete_time" "meeting_start_time"] }
def type-completer [] { ["1" "2" "3"] }
def action-completer-1 [] { ["move" "set_primary"] }
def option-completer-2 [] { ["meeting_authentication" "meeting_security" "recording_authentication"] }
def encryption-completer [] { ["auto" "no" "yes"] }
def protocol-completer [] { ["H.323" "SIP"] }
def type-completer-1 [] { ["normal" "restricted" "shared"] }
def accept-completer-1 [] { ["application/json" "application/xml" "new"] }
def type-completer-2 [] { ["1" "2" "3" "8"] }
def action-completer-2 [] { ["start" "stop"] }
def action-completer-3 [] { ["delete" "trash"] }
def status-completer [] { ["approved" "denied" "pending"] }
def action-completer-4 [] { ["approve" "deny"] }
def approval-type-completer [] { ["0" "1" "2"] }
def share-recording-completer [] { ["internally" "none" "publicly"] }
def action-completer-5 [] { ["recover"] }
def action-completer-6 [] { ["approve" "cancel" "deny"] }
def action-completer-7 [] { ["end" "recover"] }
def type-completer-3 [] { ["live" "past" "pastOne"] }
def include-fields-completer [] { ["tracking_fields"] }
def include-fields-completer-1 [] { ["registrant_id"] }
def type-completer-4 [] { ["live" "past"] }
def block-type-completer [] { ["inbound" "outbound"] }
def match-type-completer [] { ["phoneNumber" "prefix"] }
def status-completer-1 [] { ["active" "inactive"] }
def time-type-completer [] { ["endTime" "startTime"] }
def type-completer-5 [] { ["assigned" "unassigned"] }
def type-completer-6 [] { ["all" "assigned" "unassigned"] }
def extension-type-completer [] { ["autoReceptionist" "callQueue" "commonAreaPhone" "user"] }
def number-type-completer [] { ["toll" "tollfree"] }
def type-completer-7 [] { ["autoReceptionist" "commonarea" "group" "interop" "user"] }
def type-completer-8 [] { ["all" "missed"] }
def status-completer-2 [] { ["all" "read" "unread"] }
def category-type-completer [] { ["account" "all" "billing" "im" "phone_contacts" "recording" "role" "sub_account" "user" "user_settings" "webinar" "zoom_rooms"] }
def type-completer-9 [] { ["1" "3"] }
def type-completer-10 [] { ["active" "inactive"] }
def type-completer-11 [] { ["past" "pastOne"] }
def status-completer-3 [] { ["Available" "InMeeting" "Offline" "UnderConstruction"] }
def type-completer-12 [] { ["DigitalSignageOnly" "SchedulingDisplayOnly" "ZoomRoom"] }
def setting-type-completer [] { ["alert" "meeting"] }
def method-completer [] { ["zoomroom.emergency_alert_displayed"] }
def action-completer-8 [] { ["cancel" "downgrade" "upgrade"] }
def transport-protocol-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def transport-protocol2-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def transport-protocol3-completer [] { ["AUTO" "TCP" "TLS" "UDP"] }
def tsp-bridge-completer [] { ["EU_TSP_TB" "US_TSP_TB"] }
def status-completer-4 [] { ["active" "inactive" "pending"] }
def action-completer-9 [] { ["autoCreate" "create" "custCreate" "ssoCreate"] }
def action-completer-10 [] { ["delete" "disassociate"] }
def login-type-completer [] { ["0" "1" "100" "101" "99"] }
def type-completer-13 [] { ["1" "2" "3" "99"] }
def type-completer-14 [] { ["live" "scheduled" "upcoming"] }
def status-completer-5 [] { ["Available" "Away" "Do_No_Disturb"] }
def option-completer-3 [] { ["meeting_authentication" "meeting_secuirty" "recording_authentication"] }
def action-completer-11 [] { ["activate" "deactivate"] }
def type-completer-15 [] { ["token" "zak"] }
def tsp-id-completer [] { ["1" "2"] }
def type-completer-16 [] { ["5" "6" "9"] }
def action-completer-12 [] { ["end"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accounts: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, accounts: table<account_name: string, account_number: string, account_type: string, created_at: string, id: string, owner_email: string, seats: int, subscription_end_time: string, subscription_start_time: string>>"
    account-create: "record<created_at: string, id: string, owner_email: string, owner_id: string>"
    account: "record<created_at: string, id: string, options: record<billing_auto_renew: bool, meeting_connector_list: list<string>, pay_mode: string, room_connector_list: list<string>, share_mc: bool, share_rc: bool>, owner_email: string, owner_id: string, vanity_url: string>"
    account-billing: "record<address: string, apt: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string>"
    account-billing-invoices: "record<currency: string, invoices: table<balance: float, due_date: string, id: string, invoice_date: string, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float>>"
    get-account-billing-invoice: "record<balance: float, currency: string, due_date: string, id: string, invoice_date: string, invoice_items: table<charge_name: string, charge_number: string, charge_type: string, end_date: string, quantity: int, start_date: string, tax_amount: float, total_amount: float>, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float>"
    get-account-lock-settings: "record"
    account-managed-domain: "record<domains: table<domain: string, status: string>, total_records: int>"
    post-phone-sip-trunk: "record<sip_trunks: table<carrier_account: string, id: string, name: string>>"
    account-plans: "record<plan_audio: record<callout_countries: string, ddi_numbers: int, next_invoice_date: string, premium_countries: string, service_effective_date: string, status: string, tollfree_countries: string, type: string>, plan_base: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_large_meeting: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_phone: record<plan_base: record<callout_countries: string, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_calling: list<record>, plan_number: list<record>>, plan_recording: string, plan_recording_next_invoice_date: string, plan_recording_service_effective_date: string, plan_recording_status: string, plan_room_connector: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_webinar: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_zoom_rooms: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>>"
    account-plan-base-delete: "record"
    get-plan-usage: "record<plan_base: table<hosts: int, type: string, usage: int>, plan_large_meeting: table<hosts: int, type: string, usage: int>, plan_recording: record<free_storage: string, free_storage_usage: string, plan_storage: string, plan_storage_exceed: string, plan_storage_usage: string, type: string>, plan_united: record<hosts: int, name: string, type: string, usage: int>, plan_webinar: table<hosts: int, type: string, usage: int>, plan_zoom_rooms: table<hosts: int, type: string, usage: int>>"
    get-account-cloud-recording: "record<from: string, meetings: table<duration: int, host_id: string, id: string, recording_count: int, recording_files: list, start_time: string, topic: string, total_size: int, uuid: string>, next_page_token: string, page_size: int, to: string, total_records: int>"
    upload-vb: "record<id: string, is_default: bool, name: string, size: string, type: string>"
    list-internal-callout-countries: "record<callout_countries: table<code: string, id: string, name: string>, total_records: int>"
    add-callout-countries: "record<callout_countries: table<code: string, id: string, name: string>>"
    list-internal-numbers: "record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, labels: string, languages: string, number: string, type: int, visible: bool>, next_page_token: string, page_size: int, total_records: int>"
    add-internal-numbers: "record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, id: string, labels: string, languages: string, number: string, type: int, visible: bool>>"
    list-sip-trunks: "record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, outbound_caller_id: string, sip_server_address: string>, total_records: int>"
    assign-sip-trunks: "record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, sip_server_address: string>>"
    delete-sip-trunk: "record"
    account-trusted-domain: "record<trusted_domains: list<string>>"
    list-archived-files: "record<from: string, meetings: table<archive_files: list, duration: int, host_id: string, id: int, recording_count: int, start_time: string, timezone: string, topic: string, total_size: int, type: int, uuid: string>, next_page_token: string, page_size: int, to: string>"
    get-user-level-channel: "record<id: string, name: string, type: int>"
    join-channel: "record<added_at: string, id: string>"
    get-user-contacts: "record<contacts: table<email: string, first_name: string, id: string, last_name: string>, next_page_token: string, page_size: int>"
    get-user-contact: "record<direct_numbers: list<string>, email: string, extension_number: string, first_name: string, id: string, last_name: string, phone_number: string, presence_status: string>"
    get-channels: "record<channels: table<channels_settings: record, id: string, name: string, type: int>, next_page_token: string, page_size: int, total_records: int>"
    create-channel: "record<id: string, jid: string, name: string, type: int>"
    get-channel: "record<id: string, name: string, type: int>"
    list-channel-members: "record<members: table<email: string, first_name: string, id: string, last_name: string, role: string>, next_page_token: string, page_size: int, total_records: int>"
    invite-channel-members: "record<added_at: string, ids: list<string>>"
    get-chat-messages: "record<date: string, messages: table<date_time: string, id: string, message: string, reply_main_message_id: string, reply_main_message_timestamp: int, sender: string, status: string, timestamp: int>, next_page_token: string, page_size: int>"
    senda-chat-message: "record<id: string>"
    search-company-contacts: "record<contacts: table<dept: string, direct_numbers: list, email: string, extension_number: string, first_name: string, id: string, im_group_id: string, im_group_name: string, job_title: string, last_name: string, location: string, phone_number: string, presence_status: string, sip_phone_number: string>, next_page_token: string, page_size: int>"
    groups: "record<groups: table<id: string, name: string, total_members: int>, total_records: int>"
    group-create: "record<id: string, name: string, total_members: int>"
    group: "record<id: string, name: string, total_members: int>"
    group-members: "record<members: table<email: string, first_name: string, id: string, last_name: string, type: int>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int>"
    group-members-create: "record<added_at: string, ids: string>"
    upload-group-vb: "record<id: string, is_default: bool, name: string, size: string, type: string>"
    device-list: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, devices: table<id: string, encryption: string, ip: string, name: string, protocol: string>>"
    device-create: "record<id: string, encryption: string, ip: string, name: string, protocol: string>"
    delete-a-chatbot-message: "record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string>"
    edit-chatbot-message: "record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string>"
    im-chat-sessions: "record<from: string, to: string, next_page_token: string, page_size: int, sessions: table<last_message_sent_time: string, name: string, session_id: string, type: string>>"
    im-chat-messages: "record<from: string, session_id: string, to: string, next_page_token: string, page_size: int, messages: table<action: string, action_time: string, date_time: string, message: string, sender: string>>"
    im-groups: "record<total_records: int, groups: table<id: string, name: string, total_members: int, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, type: string>>"
    im-group-create: "record<id: string, name: string, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, total_members: int>"
    im-group: "record<id: string, name: string, total_members: int, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, type: string>"
    im-group-members: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, members: table<email: string, first_name: string, id: string, last_name: string, type: int>>"
    im-group-members-create: "record<added_at: string, ids: string>"
    sendimmessages: "record<id: string>"
    listimmessages: "record<date: string, messages: table<date_time: string, id: string, message: string, sender: string, timstamp: int>, next_page_token: string, page_size: int>"
    meeting: "record<assistant_id: string, host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, encrypted_password: string, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, status: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int>"
    create-batch-polls: "record<polls: table<id: string, questions: list, status: string, title: string>>"
    meeting-invitation: "record<invitation: string>"
    get-live-stream-details: "record<page_url: string, stream_key: string, stream_url: string>"
    meeting-polls: "record<polls: table<id: string, status: string, questions: list, title: string>, total_records: int>"
    meeting-poll-create: "record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>"
    meeting-poll-get: "record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>"
    recording-get: "record<account_id: string, duration: int, host_id: string, id: string, recording_count: string, start_time: string, topic: string, total_size: string, type: string, uuid: string, recording_files: table<deleted_time: string, download_url: string, file_size: float, file_type: string, id: string, meeting_id: string, play_url: string, recording_end: string, recording_start: string, recording_type: string, status: string>, download_access_token: string>"
    meeting-recording-registrants: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string>>"
    meeting-recording-registrant-create: "record<id: int, registrant_id: string, share_url: string, topic: string>"
    recording-registrants-questions-get: "record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>"
    recording-setting-update: "record<approval_type: int, authentication_domains: string, authentication_option: string, on_demand: bool, password: string, recording_authentication: bool, send_email_to_host: bool, share_recording: string, show_social_share_buttons: bool, topic: string, viewer_download: bool>"
    meeting-registrants: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>"
    meeting-registrant-create: "record<id: int, join_url: string, registrant_id: string, start_time: string, topic: string>"
    meeting-registrants-questions-get: "record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>"
    dashboard-client-feedback: "record<client_feedbacks: table<feedback_id: string, feedback_name: string, participants_count: int>, from: string, to: string, total_records: int>"
    dashboard-client-feedback-detail: "record<from: string, to: string, next_page_token: string, page_size: int, client_feedback_details: table<email: string, meeting_id: string, participant_name: string, time: string>>"
    list-meeting-satisfaction: "record<client_satisfaction: table<date: string, good_count: int, none_count: int, not_good_count: int, satisfaction_percent: int>, from: string, to: string, total_records: int>"
    dashboard-crc: "record<from: string, to: string, crc_ports_usage: table<crc_ports_hour_usage: list, date_time: string>>"
    dashboard-im: "record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, users: table<calls_receive: int, calls_send: int, email: string, emoji_receive: int, emoji_send: int, files_receive: int, files_send: int, group_receive: int, group_send: int, images_receive: int, images_send: int, total_receive: int, total_send: int, user_id: string, user_name: string, videos_receive: int, videos_send: int, voice_receive: int, voice_send: int>>"
    dashboard-issue-zoom-room: "record<from: string, to: string, total_records: int, zoom_rooms: table<id: string, issues_count: int, room_name: string>>"
    dashboard-issue-detail-zoom-room: "record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, issue_details: table<issue: string, time: string>>"
    dashboard-meetings: "record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, tracking_fields: list, user_type: string, uuid: string>>"
    dashboard-meeting-detail: "record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>"
    dashboard-meeting-participants: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, camera: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, in_room_participants: int, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, status: string, user_id: string, user_name: string, version: string, video_quality: string>>"
    dashboard-meeting-participants-qos: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: list, version: string>>"
    participant-feedback: "record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>>"
    dashboard-meeting-participant-share: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>>"
    dashboard-meeting-participant-qos: "record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string>"
    dashboard-webinars: "record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, webinars: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>>"
    dashboard-webinar-detail: "record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>"
    dashboard-webinar-participants: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, user_id: string, user_name: string, version: string, video_quality: string>>"
    dashboard-webinar-participants-qos: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: list, version: string>>"
    participant-webinar-feedback: "record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>>"
    dashboard-webinar-participant-share: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>>"
    dashboard-webinar-participant-qos: "record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string>"
    dashboard-zoom-rooms: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, zoom_rooms: table<account_type: string, calender_name: string, camera: string, device_ip: string, email: string, health: string, id: string, issues: list, last_start_time: string, location: string, microphone: string, room_name: string, speaker: string, status: string>>"
    dashboard-zoom-room-issue: "record<from: string, to: string, total_records: int, issues: table<issue_name: string, zoom_rooms_count: int>>"
    dashboard-zoom-room: "record<account_type: string, calender_name: string, camera: string, device_ip: string, email: string, health: string, id: string, issues: list<string>, last_start_time: string, location: string, microphone: string, room_name: string, speaker: string, status: string, live_meeting: record<custom_keys: list<record>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>, past_meetings: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: list<record>>>"
    list-past-meeting-files: "record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int>"
    past-meetings: "record<meetings: table<start_time: string, uuid: string>>"
    list-past-meeting-polls: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    past-meeting-details: "record<duration: int, end_time: string, host_id: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string>"
    past-meeting-participants: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<id: string, name: string, user_email: string>>"
    webinar-absentees: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>"
    list-past-webinar-files: "record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int>"
    past-webinars: "record<webinars: table<start_time: string, uuid: string>>"
    list-webinar-participants: "record<next_page_token: string, page_count: int, page_size: int, participants: table<id: string, name: string, user_email: string>, total_records: int>"
    list-past-webinar-poll-results: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    list-past-webinar-qa: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    add-auto-receptionist: "record<extension_number: int, id: string, name: string>"
    list-blocked-list: "record<blocked_list: table<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string>, next_page_token: string, page_size: int, total_records: int>"
    add-anumber-to-blocked-list: "record<id: string>"
    get-a-blocked-list: "record<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string>"
    add-byoc-number: "record<phone_numbers: table<id: string, number: string>>"
    account-call-logs: "record<call_logs: table<answer_start_time: string, call_id: string, call_type: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, id: string, owner: record, path: string, rate: string, recording_id: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: string>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int>"
    list-call-queues: "record<call_queues: table<extension_number: int, id: string, name: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int>"
    create-call-queue: "record<extension_number: int, id: string, name: string, status: string>"
    get-a-call-queue: "record<extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, name: string, phone_numbers: table<id: string, number: string, source: string>, site: record<id: string, name: string>, status: string>"
    add-members-to-call-queue: "record"
    unassign-a-phone-num-call-queue: "record"
    assign-phone-to-call-queue: "record"
    un-assign-phone-num-call-queue: "record"
    get-call-queue-recordings: "record<from: string, next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string>, to: string, total_records: string>"
    list-calling-plans: "record<calling_plans: table<assigned: int, available: int, name: string, subscribed: int, type: int>>"
    list-common-area-phones: "record<common_area_phones: table<calling_plans: list, device_type: string, display_name: string, id: string, mac_address: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int>"
    add-common-area-phone: "record<display_name: string, id: string>"
    get-a-common-area-phone: "record<device_type: string, id: string, mac_address: string, name: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string>"
    list-phone-devices: "record<devices: table<assignee: record, device_type: string, display_name: string, id: string, mac_address: string, site: record, status: string>, next_page_token: string, page_size: int, total_records: string>"
    get-a-device: "record<assignee: record<extension_number: int, id: string, name: string>, device_type: string, display_name: string, id: string, mac_address: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string>"
    list-call-logs-metrics: "record<call_logs: table<call_id: string, callee: record, caller: record, date_time: string, direction: string, duration: int, mos: string>, from: string, next_page_token: string, page_size: int, to: string, total_records: int>"
    get-call-qo-s: "record<call_id: string, callee_qos: record<receiving: list<record>, sending: list<record>>, caller_qos: record<receiving: list<record>, sending: list<record>>>"
    get-call-log-metrics-details: "record<call_id: string, callee: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, caller: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, date_time: string, direction: string, duration: int, mos: string>"
    list-account-phone-numbers: "record<next_page_token: string, page_size: int, phone_numbers: table<assignee: record, capability: list, carrier: record, display_name: string, id: string, location: string, number: string, number_type: string, sip_group: record, site: record, source: string, status: string>, total_records: int>"
    get-phone-number-details: "record<assignee: record<extension_number: int, id: string, name: string, type: string>, capability: list<string>, display_name: string, id: string, location: string, number: string, number_type: string, site: record<id: string, name: string>, source: string, status: string>"
    get-phone-recordings: "record<next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string, owner: record, recording_type: string, site: record>, total_records: int>"
    get-ps-operation-logs: "record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>>"
    list-setting-templates: "record<next_page_token: string, page_size: int, templates: table<description: string, id: string, name: string, type: string>, total_records: int>"
    add-setting-template: "record<description: string, id: string, name: string, type: string>"
    get-setting-template: "record<description: string, id: string, name: string, policy: record<ad_hoc_call_recording: record<enable: bool, recording_start_prompt: bool, recording_transcription: bool>, auto_call_recording: record<enable: bool, recording_calls: string, recording_start_prompt: bool, recording_transcription: bool>, sms: record<enable: bool, international_sms: bool>, voicemail: record<allow_transcription: bool, enable: bool>>, profile: record<area_code: string, country: string>, type: string, user_settings: record<audio_prompt_language: string, block_calls_without_caller_id: bool, call_handling: record<business_hours: record, close_hours: record>, desk_phone: record<pin_code: string>, hold_music: string>>"
    list-shared-line-groups: "record<next_page_token: string, page_size: int, shared_line_groups: table<display_name: string, extension_number: int, id: string, phone_numbers: list, site: record, status: string>, total_records: int>"
    get-a-shared-line-group: "record<display_name: string, extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, phone_numbers: table<id: string, number: string>, primary_number: string, site: record<id: string, name: string>, status: string, timezone: string>"
    list-byocsip-trunk: "record<byoc_sip_trunk: table<carrier: string, carrier_account: string, id: string, name: string, region: string, sbc_label: string>, next_page_token: string, page_size: int>"
    list-phone-sites: "record<next_page_token: string, page_size: string, sites: table<country: record, id: string, main_auto_receptionist: record, name: string, site_code: string>, total_records: string>"
    create-phone-site: "record<id: string, name: string>"
    get-a-site: "record<country: record<code: string, name: string>, id: string, main_auto_receptionist: record<extension_id: string, extension_number: int, id: string, name: string>, name: string, short_extension: record<length: int>, site_code: int>"
    list-phone-users: "record<next_page_token: string, page_size: int, total_records: int, users: table<calling_plans: list, email: string, extension_number: int, id: string, name: string, phone_user_id: string, site: record, status: string>>"
    phone-user: "record<calling_plan: table<type: int>, email: string, extension_number: int, id: string, phone_numbers: table<id: string, number: string>, phone_user_id: string, site_admin: bool, site_id: string, status: string>"
    phone-user-call-logs: "record<call_logs: table<accepted_by: record, call_id: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, forwarded_by: record, forwarded_to: record, has_recording: bool, has_voicemail: bool, id: string, outgoing_by: record, path: string, rate: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: int>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int>"
    assign-phone-number: "record<phone_numbers: table<id: string, number: string>>"
    phone-user-recordings: "record<from: string, next_page_token: string, page_count: int, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: string, id: string>, to: string, total_records: int>"
    phone-user-settings: "record<area_code: string, company_number: string, desk_phone: record<keys_positions: record<primary_number: string>>, outbound_caller: record<number: string>, outbound_caller_ids: record<is_default: bool, name: string, number: string>, voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>>"
    add-user-setting: "record<voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>>"
    phone-user-voice-mails: "record<from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int, voice_mails: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, download_url: string, duration: string, id: string, status: string>>"
    report-sign-in-sign-out-activities: "record<activity_logs: table<client_type: string, email: string, ip_address: string, time: string, type: string, version: string>, from: string, next_page_token: string, page_size: string, to: string>"
    report-cloud-recording: "record<from: string, to: string, cloud_recording_storage: table<date: string, free_usage: string, plan_usage: string, usage: string>>"
    report-daily: "record<dates: table<date: string, meeting_minutes: int, meetings: int, new_users: int, participants: int>, month: int, year: int>"
    report-meeting-details: "record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string>"
    report-meeting-participants: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, registrant_id: string, user_email: string, user_id: string>>"
    report-meeting-polls: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    report-operation-logs: "record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>>"
    report-telephone: "record<from: string, next_page_token: int, page_count: int, page_size: int, to: string, total_records: int, telephony_usage: table<call_in_number: string, country_name: string, dept: string, duration: int, end_time: string, host_email: string, host_id: string, host_name: string, meeting_id: int, meeting_type: string, phone_number: string, rate: float, signaled_number: string, start_time: string, total: float, type: string, uuid: string>>"
    report-users: "record<from: string, next_page_token: string, page_count: int, page_number: int, page_size: int, to: string, total_records: int, total_meeting_minutes: int, total_meetings: int, total_participants: int, users: table<custom_attributes: record, dept: string, email: string, id: string, meeting_minutes: int, meetings: int, participants: int, type: int, user_name: string>>"
    report-meetings: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, from: string, meetings: table<custom_keys: list, duration: int, end_time: string, id: int, participants_count: int, source: string, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string>, to: string>"
    report-webinar-details: "record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string>"
    report-webinar-participants: "record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, user_email: string, user_id: string>>"
    report-webinar-polls: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    report-webinar-qa: "record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>"
    roles: "record<roles: table<description: string, id: string, name: string, total_members: int>, total_records: int>"
    delete-role: "record"
    get-role-information: "record<description: string, id: string, name: string, privileges: list<string>, sub_account_privileges: record<second_level: int>, total_members: int>"
    role-members: "record<members: table<department: string, email: string, first_name: string, id: string, last_name: string, type: int>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int>"
    add-role-members: "record<add_at: string, ids: string>"
    list-zoom-rooms: "record<next_page_token: string, page_size: int, rooms: table<activation_code: string, id: string, location_id: string, name: string, room_id: string, status: string>>"
    add-a-room: "record<id: string, location_id: string, name: string, room_id: string, type: string>"
    get-zr-account-profile: "record<basic: record<required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>>"
    update-zr-acc-profile: "record"
    get-zr-account-settings: "record"
    update-zoom-room-acc-settings: "record"
    list-digital-signage-content: "record<contents: table<id: string, name: string>, next_page_token: string, page_size: int>"
    manage-e911signage: "record<event_id: string>"
    list-zr-locations: "record<locations: table<id: string, name: string, parent_location_id: string, type: string>, next_page_token: string, page_size: int>"
    add-azr-location: "record<id: string, name: string, parent_location_id: string, type: string>"
    get-zr-location-structure: "record<structures: list<string>>"
    get-zr-location-profile: "record<basic: record<address: string, \"description \": string, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string, timezone: string>>"
    get-zr-location-settings: "record"
    delete-a-zoom-room: "record"
    get-zr-profile: "record<basic: record<activation_code: string, hide_room_in_contacts: bool, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>>"
    update-room-profile: "record"
    list-zr-devices: "record<devices: table<app_version: string, device_system: string, device_type: string, id: string, room_name: string, status: string>>"
    get-zr-settings: "record"
    list-sip-phones: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, phones: table<authorization_name: string, domain: string, id: string, password: string, proxy_server: string, proxy_server2: string, proxy_server3: string, register_server: string, register_server2: string, register_server3: string, registration_expire_time: int, transport_protocol: string, transport_protocol2: string, transport_protocol3: string, user_email: string, user_name: string, voice_mail: string>, total_records: int>"
    delete-sip-phone: "record"
    update-sip-phone: "record"
    list-sip-trunk-numbers: "record<phone_numbers: table<country: string, number: string>, total_records: int>"
    trackingfield-list: "record<total_records: int, tracking_fields: table<id: string, field: string, recommended_values: list, required: bool, visible: bool>>"
    trackingfield-create: "record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool>"
    trackingfield-get: "record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool>"
    tsp: "record<dial_in_number_unrestricted: bool, dial_in_numbers: table<code: string, number: string, type: string>, enable: bool, master_account_setting_extended: bool, modify_credential_forbidden: bool, tsp_bridge: string, tsp_enabled: bool, tsp_provider: string>"
    users: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, users: table<created_at: string, custom_attributes: list, dept: string, email: string, first_name: string, group_ids: list, host_key: string, id: string, im_group_ids: list, last_client_version: string, last_login_time: string, last_name: string, plan_united_type: string, pmi: int, role_id: string, status: string, timezone: string, type: int, verified: int>>"
    user-create: "record<email: string, first_name: string, id: string, last_name: string, type: int>"
    user-email: "record<existed_email: bool>"
    user-zak: "record<token: string>"
    user-vanity-name: "record<existed: bool>"
    user: "record<id: string, created_at: string, dept: string, email: string, first_name: string, last_client_version: string, last_login_time: string, last_name: string, pmi: int, role_name: string, timezone: string, type: int, use_pmi: bool, account_id: string, cms_user_id: string, company: string, custom_attributes: record<key: string, name: string, value: string>, group_ids: list<string>, host_key: string, im_group_ids: list<string>, jid: string, job_title: string, language: string, location: string, login_type: int, manager: string, personal_meeting_url: string, phone_country: string, phone_number: string, phone_numbers: record<code: string, country: string, number: string, verified: bool>, pic_url: string, plan_united_type: string, role_id: string, status: string, vanity_url: string, verified: int>"
    user-assistants: "record<assistants: table<email: string, id: string>>"
    user-assistant-create: "record<add_at: string, ids: string>"
    list-meeting-templates: "record<templates: table<id: string, name: string, type: int>, total_records: int>"
    meetings: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, meetings: table<agenda: string, created_at: string, duration: int, host_id: string, id: int, join_url: string, pmi: string, start_time: string, timezone: string, topic: string, type: int, uuid: string>>"
    meeting-create: "record<assistant_id: string, host_email: string, id: int, registration_url: string, agenda: string, created_at: string, duration: int, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int>"
    user-pa-cs: "record<pac_accounts: table<conference_id: int, dedicated_dial_in_number: list, global_dial_in_numbers: list, listen_only_password: string, participant_password: string>>"
    user-permission: "record<permissions: list<string>>"
    recordings-list: "record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: table<account_id: string, duration: int, host_id: string, id: string, recording_count: string, start_time: string, topic: string, total_size: string, type: string, uuid: string, recording_files: list>>"
    user-schedulers: "record<schedulers: table<email: string, id: string, pmi: int>>"
    upload-v-buser: "record<id: string, is_default: bool, name: string, size: string, type: string>"
    user-token: "record<token: string>"
    user-ts-ps: "record<tsp_accounts: table<conference_code: string, dial_in_numbers: list, id: int, leader_pin: string, tsp_bridge: string>>"
    user-tsp-create: "record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, leader_pin: string, tsp_bridge: string>"
    user-tsp: "record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, id: int, leader_pin: string, tsp_bridge: string>"
    list-webinar-templates: "record<templates: table<id: string, name: string>, total_records: int>"
    webinars: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, webinars: table<agenda: string, created_at: string, duration: int, host_id: string, id: int, join_url: string, start_time: string, timezone: string, topic: string, type: string, uuid: string>>"
    webinar-create: "record<host_email: string, host_id: string, id: int, registrants_confirmation_email: bool, template_id: string, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int>"
    webinar: "record<host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int>"
    add-batch-webinar-registrants: "record<registrants: table<email: string, join_url: string, registrant_id: string>>"
    webinar-panelists: "record<panelists: table<id: string, email: string, name: string, join_url: string>, total_records: int>"
    webinar-panelist-create: "record<id: string, updated_at: string>"
    webinar-polls: "record<polls: table<id: string, status: string, questions: list, title: string>, total_records: int>"
    webinar-poll-create: "record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>"
    webinar-poll-get: "record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>"
    webinar-registrants: "record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>"
    webinar-registrant-create: "record<id: string, join_url: string, registrant_id: string, start_time: string, topic: string>"
    webinar-registrants-questions-get: "record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>"
    webinar-registrant-get: "record<id: string, address: string, city: string, comments: string, country: string, custom_questions: table<title: string, value: string>, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>"
    get-tracking-sources: "record<total_records: int, tracking_sources: table<id: string, registration_count: int, source_name: string, tracking_url: string, visitor_count: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accounts" "account-create" "account-disassociate" "account" "account-billing" "account-billing-update" "account-billing-invoices" "get-account-billing-invoice" "get-account-lock-settings" "update-account-lock-settings" "account-managed-domain" "account-options-update" "update-account-owner" "update-phone-settings" "set-up-account" "post-phone-sip-trunk" "update-phone-sip-trunk" "account-plans" "account-plan-create" "account-plan-addon-create" "account-plan-addon-update" "account-plan-addon-cancel" "account-plan-base-update" "account-plan-base-delete" "get-plan-usage" "get-account-cloud-recording" "account-settings" "account-settings-update" "del-vb" "upload-vb" "list-internal-callout-countries" "add-callout-countries" "delete-internal-call-out-country" "list-internal-numbers" "add-internal-numbers" "delete-internal-number" "delete-all-sip-numbers" "assign-sip-trunk-numbers" "assign-sip-config" "list-sip-trunks" "assign-sip-trunks" "delete-sip-trunk" "account-trusted-domain" "switch-user-account" "download-invoice-pdf" "list-archived-files" "delete-user-level-channel" "get-user-level-channel" "update-user-level-channel" "leave-channel" "join-channel" "remove-a-user-level-channel-member" "get-user-contacts" "get-user-contact" "get-channels" "create-channel" "delete-channel" "get-channel" "update-channel" "list-channel-members" "invite-channel-members" "remove-a-channel-member" "get-chat-messages" "senda-chat-message" "delete-chat-message" "edit-message" "search-company-contacts" "groups" "group-create" "group-delete" "group" "group-update" "get-group-lock-settings" "group-locked-settings" "group-members" "group-members-create" "group-members-delete" "update-a-group-member" "get-group-settings" "update-group-settings" "del-group-vb" "upload-group-vb" "device-list" "device-create" "device-delete" "device-update" "sendchatbot" "delete-a-chatbot-message" "edit-chatbot-message" "im-chat-sessions" "im-chat-messages" "im-groups" "im-group-create" "im-group-delete" "im-group" "im-group-update" "im-group-members" "im-group-members-create" "im-group-members-delete" "sendimmessages" "listimmessages" "in-meeting-recording-control" "meeting-delete" "meeting" "meeting-update" "create-batch-polls" "meeting-invitation" "get-live-stream-details" "meeting-live-stream-update" "meeting-live-stream-status-update" "meeting-polls" "meeting-poll-create" "meeting-poll-delete" "meeting-poll-get" "meeting-poll-update" "recording-delete" "recording-get" "meeting-recording-registrants" "meeting-recording-registrant-create" "recording-registrants-questions-get" "recording-registrant-question-update" "meeting-recording-registrant-status" "recording-setting-update" "recording-settings-update" "recording-status-update" "recording-delete-one" "recording-status-update-one" "meeting-registrants" "meeting-registrant-create" "meeting-registrants-questions-get" "meeting-registrant-question-update" "meeting-registrant-status" "meetingregistrantdelete" "meeting-status" "dashboard-client-feedback" "dashboard-client-feedback-detail" "list-meeting-satisfaction" "dashboard-crc" "dashboard-im" "dashboard-issue-zoom-room" "dashboard-issue-detail-zoom-room" "dashboard-meetings" "dashboard-meeting-detail" "dashboard-meeting-participants" "dashboard-meeting-participants-qos" "participant-feedback" "dashboard-meeting-participant-share" "dashboard-meeting-participant-qos" "dashboard-webinars" "dashboard-webinar-detail" "dashboard-webinar-participants" "dashboard-webinar-participants-qos" "participant-webinar-feedback" "dashboard-webinar-participant-share" "dashboard-webinar-participant-qos" "dashboard-zoom-rooms" "dashboard-zoom-room-issue" "dashboard-zoom-room" "list-past-meeting-files" "past-meetings" "list-past-meeting-polls" "past-meeting-details" "past-meeting-participants" "webinar-absentees" "list-past-webinar-files" "past-webinars" "list-webinar-participants" "list-past-webinar-poll-results" "list-past-webinar-qa" "add-auto-receptionist" "update-auto-receptionist" "unassign-all-phone-nums-auto-receptionist" "assign-phone-numbers-auto-receptionist" "unassign-a-phone-num-auto-receptionist" "list-blocked-list" "add-anumber-to-blocked-list" "delete-a-blocked-list" "get-a-blocked-list" "update-blocked-list" "add-byoc-number" "account-call-logs" "list-call-queues" "create-call-queue" "delete-a-call-queue" "get-a-call-queue" "update-call-queue" "change-call-queue-manager" "unassign-all-members" "add-members-to-call-queue" "unassign-member-from-call-queue" "unassign-a-phone-num-call-queue" "assign-phone-to-call-queue" "un-assign-phone-num-call-queue" "get-call-queue-recordings" "list-calling-plans" "list-common-area-phones" "add-common-area-phone" "delete-common-area-phone" "get-a-common-area-phone" "update-common-area-phone" "change-main-company-number" "list-phone-devices" "add-phone-device" "delete-a-device" "get-a-device" "update-a-device" "list-call-logs-metrics" "get-call-qo-s" "get-call-log-metrics-details" "list-account-phone-numbers" "get-phone-number-details" "update-phone-number-details" "get-phone-recordings" "get-ps-operation-logs" "list-setting-templates" "add-setting-template" "get-setting-template" "update-setting-template" "list-shared-line-groups" "create-a-shared-line-group" "delete-a-shared-line-group" "get-a-shared-line-group" "update-a-shared-line-group" "delete-members-of-slg" "add-members-to-shared-line-group" "delete-a-member-slg" "assign-phone-numbers-slg" "delete-a-phone-number-slg" "list-byocsip-trunk" "list-phone-sites" "create-phone-site" "delete-phone-site" "get-a-site" "update-site-details" "list-phone-users" "phone-user" "update-user-profile" "phone-user-call-logs" "delete-call-log" "assign-calling-plan" "unassign-calling-plan" "assign-phone-number" "unassign-phone-number" "phone-user-recordings" "phone-user-settings" "delete-user-setting" "update-user-setting" "add-user-setting" "phone-user-voice-mails" "delete-voicemail" "report-sign-in-sign-out-activities" "report-cloud-recording" "report-daily" "report-meeting-details" "report-meeting-participants" "report-meeting-polls" "report-operation-logs" "report-telephone" "report-users" "report-meetings" "report-webinar-details" "report-webinar-participants" "report-webinar-polls" "report-webinar-qa" "roles" "create-role" "delete-role" "get-role-information" "update-role" "role-members" "add-role-members" "role-member-delete" "list-zoom-rooms" "add-a-room" "get-zr-account-profile" "update-zr-acc-profile" "get-zr-account-settings" "update-zoom-room-acc-settings" "list-digital-signage-content" "manage-e911signage" "list-zr-locations" "add-azr-location" "get-zr-location-structure" "update-zoom-rooms-location-structure" "get-zr-location-profile" "update-zr-location-profile" "change-parent-location" "get-zr-location-settings" "update-zr-location-settings" "check-in-rooms" "delete-a-zoom-room" "get-zr-profile" "update-room-profile" "list-zr-devices" "change-zoom-rooms-app-version" "change-zr-location" "get-zr-settings" "update-zr-settings" "list-sip-phones" "create-sip-phone" "delete-sip-phone" "update-sip-phone" "list-sip-trunk-numbers" "trackingfield-list" "trackingfield-create" "trackingfield-delete" "trackingfield-get" "trackingfield-update" "tsp" "tsp-update" "users" "user-create" "user-email" "user-zak" "user-vanity-name" "user-delete" "user" "user-update" "user-assistants-delete" "user-assistants" "user-assistant-create" "user-assistant-delete" "user-email-update" "list-meeting-templates" "meetings" "meeting-create" "user-pa-cs" "user-password" "user-permission" "user-picture" "update-presence-status" "recordings-list" "user-schedulers-delete" "user-schedulers" "user-scheduler-delete" "user-settings" "user-settings-update" "del-user-vb" "upload-v-buser" "user-status" "user-sso-token-delete" "user-token" "user-ts-ps" "user-tsp-create" "tsp-url-update" "user-tsp-delete" "user-tsp" "user-tsp-update" "list-webinar-templates" "webinars" "webinar-create" "webinar-delete" "webinar" "webinar-update" "add-batch-webinar-registrants" "webinar-panelists-delete" "webinar-panelists" "webinar-panelist-create" "webinar-panelist-delete" "webinar-polls" "webinar-poll-create" "webinar-poll-delete" "webinar-poll-get" "webinar-poll-update" "webinar-registrants" "webinar-registrant-create" "webinar-registrants-questions-get" "webinar-registrant-question-update" "webinar-registrant-status" "delete-webinar-registrant" "webinar-registrant-get" "webinar-status" "get-tracking-sources" "commands"] | sort) } | get name | first)
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

# List sub accounts
#
# GET /accounts
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, accounts: table<account_name: string, account_number: string, account_type: string, created_at: string, id: string, owner_email: string, seats: int, subscription_end_time: string, subscription_start_time: string>>
# operationId: accounts
export def "accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a sub account
#
# POST /accounts
# Returns: record<created_at: string, id: string, owner_email: string, owner_id: string>
# operationId: accountCreate
export def "account-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --account-name: string # Name of the account. If you do not provide a value for this field, by default, the value will be set as a concatenation of "first_name" and "last_name".
  email: string # User's email address.
  first_name: string # User's first name.
  last_name: string # User's last name.
  --options: record # Account options object. — shape: {billing_auto_renew?: bool, meeting_connector_list?: list<string>, pay_mode?: "master"|"sub", room_connector_list?: list<string>, share_mc?: bool, share_rc?: bool}
  password: string # User's password. **Note:** If the account owner or admin has enabled [enhanced password requirements](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_fa9186e4-6818-4f7a-915c-2e25c19f0acd), the value provided in this field must meet those requirements. These requirements can be retrieved by calling the [Get Account Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) and referring to the `password_requirement` field present in the `security` object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: account_name, var: account_name}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: options, var: options}, {name: password, var: password}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_name: $account_name, email: $email, first_name: $first_name, last_name: $last_name, options: $options, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disassociate a sub account
#
# DELETE /accounts/{accountId}
# operationId: accountDisassociate
export def "account-disassociate" [
  account_id: string
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
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub account details
#
# GET /accounts/{accountId}
# Returns: record<created_at: string, id: string, options: record<billing_auto_renew: bool, meeting_connector_list: list<string>, pay_mode: string, room_connector_list: list<string>, share_mc: bool, share_rc: bool>, owner_email: string, owner_id: string, vanity_url: string>
# operationId: account
export def "account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get billing information
#
# GET /accounts/{accountId}/billing
# Returns: record<address: string, apt: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string>
# operationId: accountBilling
export def "account-billing" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/billing"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update billing information
#
# PATCH /accounts/{accountId}/billing
# operationId: accountBillingUpdate
export def "account-billing-update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Billing Contact's address.
  --apt: string # Billing Contact's apartment/suite.
  --city: string # Billing Contact's city.
  --country: string # Billing Contact's country.
  --email: string # Billing Contact's email address.
  --first-name: string # Billing Contact's first name.
  --last-name: string # Billing Contact's last name.
  --phone-number: string # Billing Contact's phone number.
  --state: string # Billing Contact's state.
  --zip: string # Billing Contact's zip/postal code.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/billing"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: apt, var: apt}, {name: city, var: city}, {name: country, var: country}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: phone_number, var: phone_number}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    account_id: $account_id, address: $address, apt: $apt, city: $city, country: $country, email: $email, first_name: $first_name, last_name: $last_name, phone_number: $phone_number, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List billing invoices
#
# GET /accounts/{accountId}/billing/invoices
# Returns: record<currency: string, invoices: table<balance: float, due_date: string, id: string, invoice_date: string, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float>>
# operationId: accountBillingInvoices
export def "account-billing-invoices" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date for the invoice query in `yyyy-mm-dd` format. The date range defined by the “from” and “to” parameters should not exceed one year. The range defined should fall within the past three years. (format: date)
  --to: string # End date for the invoice query in `yyyy-mm-dd` format (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/billing/invoices"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get invoice details
#
# GET /accounts/{accountId}/billing/invoices/{invoiceId}
# Returns: record<balance: float, currency: string, due_date: string, id: string, invoice_date: string, invoice_items: table<charge_name: string, charge_number: string, charge_type: string, end_date: string, quantity: int, start_date: string, tax_amount: float, total_amount: float>, invoice_number: string, status: string, target_date: string, tax_amount: float, total_amount: float>
# operationId: getAccountBillingInvoice
export def "get-account-billing-invoice" [
  account_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/billing/invoices/{invoiceId}"
    path_params: [{name: accountId, var: account_id}, {name: invoiceId, var: invoice_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get locked settings
#
# GET /accounts/{accountId}/lock_settings
# Returns: record
# operationId: getAccountLockSettings
export def "get-account-lock-settings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --option: string # `meeting_security`: Use this query parameter to view meeting security settings applied on the account.
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/lock_settings"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: option, var: option}, {name: custom_query_fields, var: custom_query_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, option: $option, custom_query_fields: $custom_query_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update locked settings
#
# PATCH /accounts/{accountId}/lock_settings
# operationId: updateAccountLockSettings
export def "update-account-lock-settings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, dscp_marking?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, original_audio?: bool, polling?: bool, ... (12 more fields)}
  --recording: record # shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, recording_authentication?: string}
  --schedule-meeting: record # shape: {audio_type?: bool, embed_password_in_join_link?: bool, enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool}
  --telephony: record # shape: {telephony_regions?: bool, third_party_audio?: bool}
  --tsp: record # shape: {call_out?: bool, show_international_numbers_link?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/lock_settings"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_notification, var: email_notification}, {name: in_meeting, var: in_meeting}, {name: recording, var: recording}, {name: schedule_meeting, var: schedule_meeting}, {name: telephony, var: telephony}, {name: tsp, var: tsp}, {name: meeting_security, var: meeting_security}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    account_id: $account_id, email_notification: $email_notification, in_meeting: $in_meeting, recording: $recording, schedule_meeting: $schedule_meeting, telephony: $telephony, tsp: $tsp, meeting_security: $meeting_security
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get managed domains
#
# GET /accounts/{accountId}/managed_domains
# Returns: record<domains: table<domain: string, status: string>, total_records: int>
# operationId: accountManagedDomain
export def "account-managed-domain" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/managed_domains"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update options
#
# PATCH /accounts/{accountId}/options
# operationId: accountOptionsUpdate
export def "account-options-update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-auto-renew: oneof<nothing, bool> # Toggle whether automatic billing renewal is on or off.
  --meeting-connector-list: list<string> # Specify the IP addresses of the Meeting Connectors that you would like to share with the sub account. Multiple values can be separated by comma. If no value is provided in this field, all the Meeting Connectors of a master account will be shared with the sub account. **Note:** This option can only be used if the value of `share_mc` is set to `true`.
  --pay-mode: string@pay-mode-completer # Payee:`master` - master account holder pays.`sub` - Sub account holder pays. (default: master)
  --room-connector-list: list<string> # Specify the IP addresses of the Room Connectors that you would like to share with the sub account. Multiple values can be separated by comma. If no value is provided in this field, all the Room Connectors of a master account will be shared with the sub account. **Note:** This option can only be used if the value of `share_rc` is set to `true`.
  --share-mc: oneof<nothing, bool> # Enable/disable the option for a sub account to use shared [Meeting Connector(s)](https://support.zoom.us/hc/en-us/articles/201363093-Getting-Started-with-the-Meeting-Connector) that are set up by the master account. Meeting Connectors can only be used by On-prem users. (default: false)
  --share-rc: oneof<nothing, bool> # Enable/disable the option for a sub account to use shared [Virtual Room Connector(s)](https://support.zoom.us/hc/en-us/articles/202134758-Getting-Started-With-Virtual-Room-Connector) that are set up by the master account. Virtual Room Connectors can only be used by On-prem users. (default: false)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/options"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_auto_renew, var: billing_auto_renew}, {name: meeting_connector_list, var: meeting_connector_list}, {name: pay_mode, var: pay_mode}, {name: room_connector_list, var: room_connector_list}, {name: share_mc, var: share_mc}, {name: share_rc, var: share_rc}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    account_id: $account_id, billing_auto_renew: $billing_auto_renew, meeting_connector_list: $meeting_connector_list, pay_mode: $pay_mode, room_connector_list: $room_connector_list, share_mc: $share_mc, share_rc: $share_rc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the account owner
#
# PUT /accounts/{accountId}/owner
# operationId: updateAccountOwner
export def "update-account-owner" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  email: string # Email address of the new owner. (format: email)
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/owner"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update BYOC settings
#
# PATCH /accounts/{accountId}/phone/settings
# operationId: updatePhoneSettings
export def "update-phone-settings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --byoc: record # shape: {enable?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/phone/settings"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: byoc, var: byoc}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, byoc: $byoc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set up a Zoom Phone account
#
# POST /accounts/{accountId}/phone/setup
# operationId: setUpAccount
export def "set-up-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emergency_address: record # Specify emergency address for the account. — shape: {address_line1: string, address_line2?: string, city?: string, country: string, state_code?: string, zip?: string}
  extension_number: string # Specify extension number that will be associated with the owner of the account. (default: 800)
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/phone/setup"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: emergency_address, var: emergency_address}, {name: extension_number, var: extension_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, emergency_address: $emergency_address, extension_number: $extension_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign SIP trunks
#
# POST /accounts/{accountId}/phone/sip_trunk/trunks
# Returns: record<sip_trunks: table<carrier_account: string, id: string, name: string>>
# operationId: postPhoneSIPTrunk
export def "post-phone-sip-trunk" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sip-trunks: list # SIP trunk configurations. — item shape: {carrier_account?: string, id?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/phone/sip_trunk/trunks"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sip_trunks, var: sip_trunks}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, sip_trunks: $sip_trunks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update SIP trunk details
#
# PATCH /accounts/{accountId}/phone/sip_trunk/trunks/{sipTrunkId}
# operationId: updatePhoneSIPTrunk
export def "update-phone-sip-trunk" [
  account_id: string
  sip_trunk_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --carrier-account: string # Account associated with the carrier.
  --name: string # Name of the SIP Trunk.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/phone/sip_trunk/trunks/{sipTrunkId}"
    path_params: [{name: accountId, var: account_id}, {name: sipTrunkId, var: sip_trunk_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: carrier_account, var: carrier_account}, {name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, sip_trunk_id: $sip_trunk_id, carrier_account: $carrier_account, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get plan Information
#
# GET /accounts/{accountId}/plans
# Returns: record<plan_audio: record<callout_countries: string, ddi_numbers: int, next_invoice_date: string, premium_countries: string, service_effective_date: string, status: string, tollfree_countries: string, type: string>, plan_base: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_large_meeting: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_phone: record<plan_base: record<callout_countries: string, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_calling: list<record>, plan_number: list<record>>, plan_recording: string, plan_recording_next_invoice_date: string, plan_recording_service_effective_date: string, plan_recording_status: string, plan_room_connector: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_webinar: table<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>, plan_zoom_rooms: record<hosts: int, next_invoice_date: string, service_effective_date: string, status: string, type: string>>
# operationId: accountPlans
export def "account-plans" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/plans"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Subscribe plans
#
# POST /accounts/{accountId}/plans
# operationId: accountPlanCreate
export def "account-plan-create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --contact: record # Billing Contact object. — shape: {address: string, apt?: string, city: string, country: string, email: string, first_name: string, last_name: string, phone_number: string, state: string, zip: string}
  --plan-audio: record # Additional audio conferencing plan type (https://marketplace.zoom.us/docs/api-reference/other-references/plans#audio-conferencing-plans). — shape: {callout_countries?: string, ddi_numbers?: int, premium_countries?: string, tollfree_countries?: string, type?: string}
  plan_base: record # Account base plan object. — shape: {hosts: int, type: string}
  --plan-large-meeting: list # Additional large meeting Plans. — item shape: {hosts?: int, type?: string}
  --plan-phone: record # Phone Plan Object — shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
  --plan-recording: string # Additional cloud recording plan.
  --plan-room-connector: record # Account plan object. — shape: {hosts?: int, type?: string}
  --plan-webinar: list # Additional webinar plans. — item shape: {hosts?: int, type?: string}
  --plan-zoom-rooms: record # Account plan object. — shape: {hosts?: int, type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/plans"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contact, var: contact}, {name: plan_audio, var: plan_audio}, {name: plan_base, var: plan_base}, {name: plan_large_meeting, var: plan_large_meeting}, {name: plan_phone, var: plan_phone}, {name: plan_recording, var: plan_recording}, {name: plan_room_connector, var: plan_room_connector}, {name: plan_webinar, var: plan_webinar}, {name: plan_zoom_rooms, var: plan_zoom_rooms}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 300]
    auth: bearer
  } {
    account_id: $account_id, contact: $contact, plan_audio: $plan_audio, plan_base: $plan_base, plan_large_meeting: $plan_large_meeting, plan_phone: $plan_phone, plan_recording: $plan_recording, plan_room_connector: $plan_room_connector, plan_webinar: $plan_webinar, plan_zoom_rooms: $plan_zoom_rooms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Subscribe additional plan
#
# POST /accounts/{accountId}/plans/addons
# operationId: accountPlanAddonCreate
export def "account-plan-addon-create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hosts: int # Number of hosts for this plan.
  type: string # Account plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
  --plan-details: record # Phone Plan Object — shape: {plan_base?: record, plan_calling?: list, plan_number?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/plans/addons"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hosts, var: hosts}, {name: type, var: type}, {name: plan_details, var: plan_details}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, hosts: $hosts, type: $type, plan_details: $plan_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an additional plan
#
# PUT /accounts/{accountId}/plans/addons
# operationId: accountPlanAddonUpdate
export def "account-plan-addon-update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  hosts: int # Number of hosts for this plan.
  type: string # Account plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/plans/addons"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hosts, var: hosts}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    account_id: $account_id, hosts: $hosts, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel additional plans
#
# PATCH /accounts/{accountId}/plans/addons/status
# operationId: accountPlanAddonCancel
export def "account-plan-addon-cancel" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string@action-completer # The action that needs to be taken for this sub account. Value must be set to "cancel".
  --comment: string # Additional comments about the cancellation decision.
  --reason: int@reason-completer # The reason for the cancellation of plan. Reason options:`1` - I am no longer working remote.`2` - I had challenges getting the support I needed.`3` - Features in the Basic Free Plan are sufficient.`4` - The expense is too high.`5` - I purchased the wrong product. `6` - Paid purchase not needed right now, will repurchase in the future.
  --type: string # Plan [type](https://marketplace.zoom.us/docs/api-reference/other-references/plans).
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/plans/addons/status"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: comment, var: comment}, {name: reason, var: reason}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    account_id: $account_id, action: $action, comment: $comment, reason: $reason, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a base plan
#
# PUT /accounts/{accountId}/plans/base
# operationId: accountPlanBaseUpdate
export def "account-plan-base-update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  hosts: int # Account base plan number of hosts. For a Pro Plan please select a value between 1 and 9. For a Business Plan please select a value between 10 and 49. For a Education Plan please select a value between 20 and 149. For a Free Trial Plan please select a value between 1 and 9999.
  type: string # Account base plan type. (https://marketplace.zoom.us/docs/api-reference/other-references/plans)
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/plans/base"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hosts, var: hosts}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    account_id: $account_id, hosts: $hosts, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a base plan
#
# PATCH /accounts/{accountId}/plans/base/status
# Returns: record
# operationId: accountPlanBaseDelete
export def "account-plan-base-delete" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  action: string # The action that needs to be taken for this sub account. Value must be set to "cancel".
  --comment: string # Additional comments about the cancellation decision.
  --reason: int@reason-completer # The reason for the cancellation of plan. Reason options:`1` - I am no longer working remote.`2` - I had challenges getting the support I needed.`3` - Features in the Basic Free Plan are sufficient.`4` - The expense is too high.`5` - I purchased the wrong product. `6` - Paid purchase not needed right now, will repurchase in the future.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/plans/base/status"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: comment, var: comment}, {name: reason, var: reason}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    account_id: $account_id, action: $action, comment: $comment, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get plan usage
#
# GET /accounts/{accountId}/plans/usage
# Returns: record<plan_base: table<hosts: int, type: string, usage: int>, plan_large_meeting: table<hosts: int, type: string, usage: int>, plan_recording: record<free_storage: string, free_storage_usage: string, plan_storage: string, plan_storage_exceed: string, plan_storage_usage: string, type: string>, plan_united: record<hosts: int, name: string, type: string, usage: int>, plan_webinar: table<hosts: int, type: string, usage: int>, plan_zoom_rooms: table<hosts: int, type: string, usage: int>>
# operationId: getPlanUsage
export def "get-plan-usage" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/plans/usage"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List recordings of an account
#
# GET /accounts/{accountId}/recordings
# Returns: record<from: string, meetings: table<duration: int, host_id: string, id: string, recording_count: int, recording_files: list, start_time: string, topic: string, total_size: int, uuid: string>, next_page_token: string, page_size: int, to: string, total_records: int>
# operationId: getAccountCloudRecording
export def "get-account-cloud-recording" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --from: string # The start date in UTC for the monthly range for which you would like to retrieve recordings. The maximum range can be a month. If no value is provided for this field, the default will be current date. For example, if you make the API request on June 30, 2020, without providing the “from” and “to” parameters, by default the value of 'from' field will be “2020-06-30” and the value of the 'to' field will be “2020-07-01”. (format: date-time)
  --to: string # The end date for the monthly range for which you would like to retrieve recordings. The maximum range can be a month. (format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/recordings"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, page_size: $page_size, next_page_token: $next_page_token, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get settings
#
# GET /accounts/{accountId}/settings
# operationId: accountSettings
export def "account-settings" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the account.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the account.`security`: Use this query parameter to view security settings such as password requirements for user login, two factor authentication etc., applied on the account. `meeting_security`: Use this query parameter to view meeting security settings applied on the account. (allows empty value)
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> any {
  http-request {
    method: get
    path: "/accounts/{accountId}/settings"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: option, var: option}, {name: custom_query_fields, var: custom_query_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, option: $option, custom_query_fields: $custom_query_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update settings
#
# PATCH /accounts/{accountId}/settings
# operationId: accountSettingsUpdate
export def "account-settings-update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --option: string@option-completer-1 # allows empty value
  --email-notification: record # Account Settings: Notification. — shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_avaliable_reminder?: bool, jbh_reminder?: bool, low_host_count_reminder?: bool, schedule_for_reminder?: bool}
  --feature: record # Account Settings: Feature. — shape: {meeting_capacity?: int}
  --in-meeting: record # Account Settings: In Meeting. — shape: {alert_guest_join?: bool, allow_live_streaming?: bool, allow_participants_to_rename?: bool, allow_show_zoom_windows?: bool, annotation?: bool, anonymous_question_answer?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", ... (34 more fields)}
  --integration: record # Account Settings: Integration. — shape: {box?: bool, dropbox?: bool, google_calendar?: bool, google_drive?: bool, kubi?: bool, microsoft_one_drive?: bool}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # Account Settings: Recording. — shape: {account_user_access_recording?: bool, allow_recovery_deleted_cloud_recordings?: bool, archive?: record, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, ... (7 more fields)}
  --schedule-meeting: record # Account Settings: Schedule Meeting. — shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", enforce_login?: bool, enforce_login_domains?: string, enforce_login_with_domains?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, not_store_meeting_topic?: bool, participant_video?: bool, personal_meeting?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", require_password_for_scheduled_meetings?: bool, ... (3 more fields)}
  --security: record # [Security settings](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_bf8a25f6-9a66-447a-befd-f02ed3404f89) of an Account. — shape: {admin_change_name_pic?: bool, hide_billing_info?: bool, import_photos_from_devices?: bool, password_requirement?: record, sign_again_period_for_inactivity_on_client?: int, sign_again_period_for_inactivity_on_web?: int, sign_in_with_two_factor_auth?: "all"|"group"|"role"|"none", sign_in_with_two_factor_auth_groups?: list<string>, sign_in_with_two_factor_auth_roles?: list<string>}
  --telephony: record # Account Settings Update: Telephony. — shape: {audio_conference_info?: string, telephony_regions?: record, third_party_audio?: bool}
  --tsp: record # Account Settings: TSP. — shape: {call_out?: bool, call_out_countries?: list, display_toll_free_numbers?: bool, show_international_numbers_link?: bool}
  --zoom-rooms: record # Account Settings: Zoom Rooms. — shape: {auto_start_stop_scheduled_meetings?: bool, cmr_for_instant_meeting?: bool, force_private_meeting?: bool, hide_host_information?: bool, list_meetings_with_calendar?: bool, start_airplay_manually?: bool, ultrasonic?: bool, upcoming_meeting_alert?: bool, weekly_system_restart?: bool, zr_post_meeting_feedback?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/settings"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: option, var: option}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_notification, var: email_notification}, {name: feature, var: feature}, {name: in_meeting, var: in_meeting}, {name: integration, var: integration}, {name: profile, var: profile}, {name: recording, var: recording}, {name: schedule_meeting, var: schedule_meeting}, {name: security, var: security}, {name: telephony, var: telephony}, {name: tsp, var: tsp}, {name: zoom_rooms, var: zoom_rooms}, {name: meeting_security, var: meeting_security}]}
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    account_id: $account_id, option: $option, email_notification: $email_notification, feature: $feature, in_meeting: $in_meeting, integration: $integration, profile: $profile, recording: $recording, schedule_meeting: $schedule_meeting, security: $security, telephony: $telephony, tsp: $tsp, zoom_rooms: $zoom_rooms, meeting_security: $meeting_security
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete virtual background files
#
# DELETE /accounts/{accountId}/settings/virtual_backgrounds
# operationId: delVB
export def "del-vb" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountId}/settings/virtual_backgrounds"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: file_ids, var: file_ids}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, file_ids: $file_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload virtual background files
#
# POST /accounts/{accountId}/settings/virtual_backgrounds
# Returns: record<id: string, is_default: bool, name: string, size: string, type: string>
# operationId: uploadVB
export def "upload-vb" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file: string # Provide the file's path here.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/settings/virtual_backgrounds"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List internal call-out countries
#
# GET /accounts/{accountId}/sip_trunk/callout_countries
# Returns: record<callout_countries: table<code: string, id: string, name: string>, total_records: int>
# operationId: listInternalCalloutCountries
export def "list-internal-callout-countries" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/sip_trunk/callout_countries"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add internal call-out countries
#
# POST /accounts/{accountId}/sip_trunk/callout_countries
# Returns: record<callout_countries: table<code: string, id: string, name: string>>
# operationId: addCalloutCountries
export def "add-callout-countries" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  callout_countries: list # List of callout countries. — item shape: {id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/sip_trunk/callout_countries"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: callout_countries, var: callout_countries}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, callout_countries: $callout_countries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete internal call-out country
#
# DELETE /accounts/{accountId}/sip_trunk/callout_countries/{countryId}
# operationId: deleteInternalCallOutCountry
export def "delete-internal-call-out-country" [
  account_id: string
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/accounts/{accountId}/sip_trunk/callout_countries/{countryId}"
    path_params: [{name: accountId, var: account_id}, {name: countryId, var: country_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, country_id: $country_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List internal numbers
#
# GET /accounts/{accountId}/sip_trunk/internal_numbers
# Returns: record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, labels: string, languages: string, number: string, type: int, visible: bool>, next_page_token: string, page_size: int, total_records: int>
# operationId: listInternalNumbers
export def "list-internal-numbers" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}/sip_trunk/internal_numbers"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add internal numbers
#
# POST /accounts/{accountId}/sip_trunk/internal_numbers
# Returns: record<internal_numbers: table<allow_for_external_meetings: bool, allow_join: bool, country: string, display_number: string, id: string, labels: string, languages: string, number: string, type: int, visible: bool>>
# operationId: addInternalNumbers
export def "add-internal-numbers" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --internal-numbers: list # item shape: {allow_for_external_meetings?: bool, allow_join?: bool, country: string, display_number: string, labels: string, languages: "en-GB"|"en-US"|"de-DE", number: string, type: "0"|"1", visible?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/sip_trunk/internal_numbers"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: internal_numbers, var: internal_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, internal_numbers: $internal_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an internal number
#
# DELETE /accounts/{accountId}/sip_trunk/internal_numbers/{numberId}
# operationId: deleteInternalNumber
export def "delete-internal-number" [
  account_id: string
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/accounts/{accountId}/sip_trunk/internal_numbers/{numberId}"
    path_params: [{name: accountId, var: account_id}, {name: numberId, var: number_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, number_id: $number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete all numbers
#
# DELETE /accounts/{accountId}/sip_trunk/numbers
# operationId: deleteAllSipNumbers
export def "delete-all-sip-numbers" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/accounts/{accountId}/sip_trunk/numbers"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign numbers
#
# POST /accounts/{accountId}/sip_trunk/numbers
# operationId: assignSipTrunkNumbers
export def "assign-sip-trunk-numbers" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-numbers: list<string> # Phone number(s) to be assigned to the sub account.
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/sip_trunk/numbers"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign SIP trunk configuration
#
# PATCH /accounts/{accountId}/sip_trunk/settings
# operationId: assignSIPConfig
export def "assign-sip-config" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --enable: oneof<nothing, bool> # Enable or delete the configuration. The values can be one of the following: `true`: Enable configuration. `false`: Delete configuration
  --show-callout-internal-number: oneof<nothing, bool> # If the value of this option is set to `true`, the call-out numbers provided by the Zoom carrier partners will be displayed in the account's list of available call-out numbers in the Zoom Web Portal and Zoom Client.
  --show-zoom-provided-callout-countries: int # If the value of this option is set to `0`, the call-out countries list provided by Zoom will be [displayed](https://support.zoom.us/hc/en-us/articles/200942859-Using-telephone-call-out) in the account's list of available call-out countries. If the value of this option is set to `1`, the Zoom provided call-out countries will be hidden from the user's account. If the value of this option is set to `2`, all Zoom provided countries will be deleted and only internal countries (provided by carrier partners) will be used.
  --show-zoom-provided-numbers: int@show-zoom-provided-numbers-completer # If the value of this option is set to `0`, the numbers provided by Zoom will be displayed in the account's list of available call-out and call-in numbers in the Zoom Web Portal and Zoom Client. If the value of this option is set to `1`, the Zoom provided numbers will be shown in the Zoom Web Portal but will not be used unless specified by the user. If the value of this option is set to `2`, all Zoom provided numbers will be deleted and only internal numbers (provided by carrier partners) will be used.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/accounts/{accountId}/sip_trunk/settings"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enable, var: enable}, {name: show_callout_internal_number, var: show_callout_internal_number}, {name: show_zoom_provided_callout_countries, var: show_zoom_provided_callout_countries}, {name: show_zoom_provided_numbers, var: show_zoom_provided_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, enable: $enable, show_callout_internal_number: $show_callout_internal_number, show_zoom_provided_callout_countries: $show_zoom_provided_callout_countries, show_zoom_provided_numbers: $show_zoom_provided_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List SIP trunks
#
# GET /accounts/{accountId}/sip_trunk/trunks
# Returns: record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, outbound_caller_id: string, sip_server_address: string>, total_records: int>
# operationId: listSIPTrunks
export def "list-sip-trunks" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/sip_trunk/trunks"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign SIP trunks
#
# POST /accounts/{accountId}/sip_trunk/trunks
# Returns: record<sip_trunks: table<dnis: string, id: string, name: string, number_prefix: string, sip_server_address: string>>
# operationId: assignSIPTrunks
export def "assign-sip-trunks" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sip-trunks: list # Array of one or more SIP Trunk objects. — item shape: {dnis?: string, id?: string, outbound_caller_id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountId}/sip_trunk/trunks"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: sip_trunks, var: sip_trunks}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, sip_trunks: $sip_trunks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a SIP trunk
#
# DELETE /accounts/{accountId}/sip_trunk/trunks/{trunkId}
# Returns: record
# operationId: deleteSIPTrunk
export def "delete-sip-trunk" [
  account_id: string
  trunk_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/sip_trunk/trunks/{trunkId}"
    path_params: [{name: accountId, var: account_id}, {name: trunkId, var: trunk_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, trunk_id: $trunk_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get trusted domains
#
# GET /accounts/{accountId}/trusted_domains
# Returns: record<trusted_domains: list<string>>
# operationId: accountTrustedDomain
export def "account-trusted-domain" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/accounts/{accountId}/trusted_domains"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Switch a user's account
#
# PUT /accounts/{accountId}/users/{userId}/account
# operationId: switchUserAccount
export def "switch-user-account" [
  account_id: string
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
  --body-account-id: string # The Account ID of the account to which you would like move the user to. (spec name: account_id)
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}/users/{userId}/account"
    path_params: [{name: accountId, var: account_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: body_account_id, required: true}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, user_id: $user_id, body_account_id: $body_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Download an invoice file
#
# GET /api/download/billing/invoices/{invoiceId}
# operationId: downloadInvoicePDF
export def "download-invoice-pdf" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/api/download/billing/invoices/{invoiceId}"
    path_params: [{name: invoiceId, var: invoice_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    invoice_id: $invoice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List archived files
#
# GET /archive_files
# Returns: record<from: string, meetings: table<archive_files: list, duration: int, host_id: string, id: int, recording_count: int, start_time: string, timezone: string, topic: string, total_size: int, type: int, uuid: string>, next_page_token: string, page_size: int, to: string>
# operationId: listArchivedFiles
export def "list-archived-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --from: string # Start date for the query in "yyyy-MM-dd'T'HH:mm:ss'Z'" format. The duration for the query defined using the "from" and "to" parameters should not exceed 7 days as this API only provides a week's data at once.
  --to: string # End date for the query in "yyyy-MM-dd'T'HH:mm:ss'Z'" format.
  --query-data-type: string@query-data-type-completer # Query data type for `from` and `to`. (default: meeting_start_time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/archive_files"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to}, {name: query_data_type, var: query_data_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token, from: $from, to: $to, query_data_type: $query_data_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a channel
#
# DELETE /chat/channels/{channelId}
# operationId: deleteUserLevelChannel
export def "delete-user-level-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/chat/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a channel
#
# GET /chat/channels/{channelId}
# Returns: record<id: string, name: string, type: int>
# operationId: getUserLevelChannel
export def "get-user-level-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/chat/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a channel
#
# PATCH /chat/channels/{channelId}
# operationId: updateUserLevelChannel
export def "update-user-level-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A new name for the channel.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/chat/channels/{channelId}"
    path_params: [{name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Leave a channel
#
# DELETE /chat/channels/{channelId}/members/me
# operationId: leaveChannel
export def "leave-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/chat/channels/{channelId}/members/me"
    path_params: [{name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Join a channel
#
# POST /chat/channels/{channelId}/members/me
# Returns: record<added_at: string, id: string>
# operationId: joinChannel
export def "join-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/chat/channels/{channelId}/members/me"
    path_params: [{name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member
#
# DELETE /chat/channels/{channelId}/members/{memberId}
# operationId: removeAUserLevelChannelMember
export def "remove-a-user-level-channel-member" [
  channel_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/chat/channels/{channelId}/members/{memberId}"
    path_params: [{name: channelId, var: channel_id}, {name: memberId, var: member_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    channel_id: $channel_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List user's contacts
#
# GET /chat/users/me/contacts
# Returns: record<contacts: table<email: string, first_name: string, id: string, last_name: string>, next_page_token: string, page_size: int>
# operationId: getUserContacts
export def "get-user-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # The type of contact. The value can be one of the following: `company`: Contacts from the user's organization. `external`: External contacts. (default: company)
  --page-size: int # The number of records returned with a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat/users/me/contacts"
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's contact details
#
# GET /chat/users/me/contacts/{contactId}
# Returns: record<direct_numbers: list<string>, email: string, extension_number: string, first_name: string, id: string, last_name: string, phone_number: string, presence_status: string>
# operationId: getUserContact
export def "get-user-contact" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-presence-status: oneof<nothing, bool> # The presence status of the contact. Include this query parameter with a value of `true` to get the presence status of the contact in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat/users/me/contacts/{contactId}"
    path_params: [{name: contactId, var: contact_id}]
    query: [{name: query_presence_status, var: query_presence_status}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    contact_id: $contact_id, query_presence_status: $query_presence_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List user's channels
#
# GET /chat/users/{userId}/channels
# Returns: record<channels: table<channels_settings: record, id: string, name: string, type: int>, next_page_token: string, page_size: int, total_records: int>
# operationId: getChannels
export def "get-channels" [
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
  --page-size: int # The number of records returned from a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat/users/{userId}/channels"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a channel
#
# POST /chat/users/{userId}/channels
# Returns: record<id: string, jid: string, name: string, type: int>
# operationId: createChannel
export def "create-channel" [
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
  --members: list # Member(s) to include in the channel. A max of 5 members can be added to the channel at once with this API. — item shape: {email: string}
  --name: string # Name of the channel.
  --type: int@type-completer # Type of the channel. The value can be one of the following: `1`: Private channel. In this type of channel, members must be invited to join a channel. `2`: Private channel with members that belong to one Zoom account. Members in this channel should be invited and the members should be from the same organization. `3`: Public channel. Anyone can search for this channel and join the channel. `4`: New chat. This is an instant channel which can be created by adding members to a new chat.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat/users/{userId}/channels"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, members: $members, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a channel
#
# DELETE /chat/users/{userId}/channels/{channelId}
# operationId: deleteChannel
export def "delete-channel" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/chat/users/{userId}/channels/{channelId}"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a channel
#
# GET /chat/users/{userId}/channels/{channelId}
# Returns: record<id: string, name: string, type: int>
# operationId: getChannel
export def "get-channel" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/chat/users/{userId}/channels/{channelId}"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a channel
#
# PATCH /chat/users/{userId}/channels/{channelId}
# operationId: updateChannel
export def "update-channel" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # A new name for the channel.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/chat/users/{userId}/channels/{channelId}"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List channel members
#
# GET /chat/users/{userId}/channels/{channelId}/members
# Returns: record<members: table<email: string, first_name: string, id: string, last_name: string, role: string>, next_page_token: string, page_size: int, total_records: int>
# operationId: listChannelMembers
export def "list-channel-members" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned with a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat/users/{userId}/channels/{channelId}/members"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Invite channel members
#
# POST /chat/users/{userId}/channels/{channelId}/members
# Returns: record<added_at: string, ids: list<string>>
# operationId: inviteChannelMembers
export def "invite-channel-members" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # Members of a channel. You can invite up to a max number of 5 members with a single API call. — item shape: {email: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat/users/{userId}/channels/{channelId}/members"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a member
#
# DELETE /chat/users/{userId}/channels/{channelId}/members/{memberId}
# operationId: removeAChannelMember
export def "remove-a-channel-member" [
  user_id: string
  channel_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/chat/users/{userId}/channels/{channelId}/members/{memberId}"
    path_params: [{name: userId, var: user_id}, {name: channelId, var: channel_id}, {name: memberId, var: member_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List user's chat messages
#
# GET /chat/users/{userId}/messages
# Returns: record<date: string, messages: table<date_time: string, id: string, message: string, reply_main_message_id: string, reply_main_message_timestamp: int, sender: string, status: string, timestamp: int>, next_page_token: string, page_size: int>
# operationId: getChatMessages
export def "get-chat-messages" [
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
  --to-contact: string # The email address of a chat contact with whom the current user chatted. Messages that were sent and/or received between the user and the contact is displayed. Note: You must provide either `contact` or `channel` as a query parameter to retrieve messages either from an individual or a chat channel.
  --to-channel: string # The channel Id of a channel inside which the current user had chat conversations. Messages that were sent and/or received between the user and the channel is displayed. Note: You must provide either `contact` or `channel` as a query parameter to retrieve messages either from an individual or a chat channel.
  --date: string # The query date for which you would like to get the chat messages. (format: date)
  --page-size: int # The number of records returned with a single API call. (default: 10)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-deleted-and-edited-message: string # **Optional** Set the value of this field to `true` to include edited and deleted messages in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chat/users/{userId}/messages"
    path_params: [{name: userId, var: user_id}]
    query: [{name: to_contact, var: to_contact}, {name: to_channel, var: to_channel}, {name: date, var: date}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_deleted_and_edited_message, var: include_deleted_and_edited_message}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, to_contact: $to_contact, to_channel: $to_channel, date: $date, page_size: $page_size, next_page_token: $next_page_token, include_deleted_and_edited_message: $include_deleted_and_edited_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Send a chat message
#
# POST /chat/users/{userId}/messages
# Returns: record<id: string>
# operationId: sendaChatMessage
export def "senda-chat-message" [
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
  --at-items: list # [Chat mentions](https://support.zoom.us/hc/en-us/articles/360037567431-Using-chat-mentions-and-slash-commands) object. Use this object to include mentions in the message that will be sent to a channel. — item shape: {at_contact?: string, at_type?: "1"|"2", end_position?: int, start_position?: int}
  message: string # The message to be sent.
  --to-channel: string # The Channel Id of the channel where you would like to send a message.
  --to-contact: string # The email address of the contact to whom you would like to send the message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/chat/users/{userId}/messages"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: at_items, var: at_items}, {name: message, var: message}, {name: to_channel, var: to_channel}, {name: to_contact, var: to_contact}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, at_items: $at_items, message: $message, to_channel: $to_channel, to_contact: $to_contact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a message
#
# DELETE /chat/users/{userId}/messages/{messageId}
# operationId: deleteChatMessage
export def "delete-chat-message" [
  user_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to-contact: string # The userId or email address of a chat contact to whom you previously sent the message. Note: You must provide either `to_contact` or `to_channel` as a query parameter to delete a message that was previously sent to either an individual or a chat channel respectively.
  --to-channel: string # The channel Id of the channel where you would like to send the message. You must provide either `to_contact` or `to_channel` as a query parameter to delete a message that was previously sent to either an individual or a chat channel
]: nothing -> any {
  http-request {
    method: delete
    path: "/chat/users/{userId}/messages/{messageId}"
    path_params: [{name: userId, var: user_id}, {name: messageId, var: message_id}]
    query: [{name: to_contact, var: to_contact}, {name: to_channel, var: to_channel}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, message_id: $message_id, to_contact: $to_contact, to_channel: $to_channel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a message
#
# PUT /chat/users/{userId}/messages/{messageId}
# operationId: editMessage
export def "edit-message" [
  user_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # The edited message.
  --to-channel: string # The Channel ID of the channel where you sent the message.You must provide either `to_contact` or `to_channel` parameter in the API request. Channel ID can be retrieved from List User's Channels API.
  --to-contact: string # The email address of the contact to whom the message was sent. You must provide either `to_contact` or `to_channel` parameter in the API request.
]: any -> any {
  $in | http-request {
    method: put
    path: "/chat/users/{userId}/messages/{messageId}"
    path_params: [{name: userId, var: user_id}, {name: messageId, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: to_channel, var: to_channel}, {name: to_contact, var: to_contact}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, message_id: $message_id, message: $message, to_channel: $to_channel, to_contact: $to_contact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search company contacts
#
# GET /contacts
# Returns: record<contacts: table<dept: string, direct_numbers: list, email: string, extension_number: string, first_name: string, id: string, im_group_id: string, im_group_name: string, job_title: string, last_name: string, location: string, phone_number: string, presence_status: string, sip_phone_number: string>, next_page_token: string, page_size: int>
# operationId: searchCompanyContacts
export def "search-company-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --search-key: string # Provide the keyword - either first name, last name or email of the contact whom you have to search for. (required)
  --query-presence-status: string # Set `query_presence_status` to `true` in order to include the presence status of a contact in the response.
  --page-size: int # The number of records to be returned with a single API call. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contacts"
    query: [{name: search_key, var: search_key, required: true}, {name: query_presence_status, var: query_presence_status}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    search_key: $search_key, query_presence_status: $query_presence_status, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List groups
#
# GET /groups
# Returns: record<groups: table<id: string, name: string, total_members: int>, total_records: int>
# operationId: groups
export def "groups" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/groups"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a group
#
# POST /groups
# Returns: record<id: string, name: string, total_members: int>
# operationId: groupCreate
export def "group-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Group name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 300]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a group
#
# DELETE /groups/{groupId}
# operationId: groupDelete
export def "group-delete" [
  group_id: string
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a group
#
# GET /groups/{groupId}
# Returns: record<id: string, name: string, total_members: int>
# operationId: group
export def "group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a group
#
# PATCH /groups/{groupId}
# operationId: groupUpdate
export def "group-update" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Group name. It must be unique to one account and less than 128 characters.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    group_id: $group_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get locked settings
#
# GET /groups/{groupId}/lock_settings
# operationId: getGroupLockSettings
export def "get-group-lock-settings" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string # Specify `meeting_security` as the value of this field if you would like to view security settings applied on a meeting hosted by the users in this group.
]: nothing -> any {
  http-request {
    method: get
    path: "/groups/{groupId}/lock_settings"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: custom_query_fields, var: custom_query_fields}, {name: option, var: option}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, custom_query_fields: $custom_query_fields, option: $option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update locked settings
#
# PATCH /groups/{groupId}/lock_settings
# operationId: groupLockedSettings
export def "group-locked-settings" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string # Specify `meeting_security` as the value of this field if you would like to view security settings applied on a meeting hosted by the users in this group.
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, original_audio?: bool, polling?: bool, post_meeting_feedback?: bool, ... (13 more fields)}
  --recording: record # shape: {account_user_access_recording?: bool, auto_delete_cmr?: bool, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, recording_authentication?: string}
  --schedule-meeting: record # shape: {audio_type?: bool, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_authentication?: bool, mute_upon_entry?: bool, participant_video?: bool, personal_meeting?: bool, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
  --telephony: record # shape: {telephony_regions?: bool, third_party_audio?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/groups/{groupId}/lock_settings"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: custom_query_fields, var: custom_query_fields}, {name: option, var: option}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_notification, var: email_notification}, {name: in_meeting, var: in_meeting}, {name: recording, var: recording}, {name: schedule_meeting, var: schedule_meeting}, {name: telephony, var: telephony}, {name: meeting_security, var: meeting_security}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, custom_query_fields: $custom_query_fields, option: $option, email_notification: $email_notification, in_meeting: $in_meeting, recording: $recording, schedule_meeting: $schedule_meeting, telephony: $telephony, meeting_security: $meeting_security
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List group members
#
# GET /groups/{groupId}/members
# Returns: record<members: table<email: string, first_name: string, id: string, last_name: string, type: int>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int>
# operationId: groupMembers
export def "group-members" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups/{groupId}/members"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add group members
#
# POST /groups/{groupId}/members
# Returns: record<added_at: string, ids: string>
# operationId: groupMembersCreate
export def "group-members-create" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # List of Group members — item shape: {email?: string, id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/members"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: bearer
  } {
    group_id: $group_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a group member
#
# DELETE /groups/{groupId}/members/{memberId}
# operationId: groupMembersDelete
export def "group-members-delete" [
  group_id: string
  member_id: string
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
    path: "/groups/{groupId}/members/{memberId}"
    path_params: [{name: groupId, var: group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    group_id: $group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a group member
#
# PATCH /groups/{groupId}/members/{memberId}
# operationId: updateAGroupMember
export def "update-a-group-member" [
  group_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  action: string@action-completer-1 # Specify the type of action to be performed: `move`: Simultaneously remove a member from one group and move the member to a different group. `set_primary`: Set a primary group for the user.
  --target-group-id: string # Can be retrieved by calling [GET /groups](https://marketplace.zoom.us/docs/api-reference/zoom-api/groups/groups) API. To move a user, use this field to specify the groupId of the group where the member is to be moved. To set a primary group for the user, provide the groupId of the group which is going to be the primary group.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/groups/{groupId}/members/{memberId}"
    path_params: [{name: groupId, var: group_id}, {name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: target_group_id, var: target_group_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, member_id: $member_id, action: $action, target_group_id: $target_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a group's settings
#
# GET /groups/{groupId}/settings
# operationId: getGroupSettings
export def "get-group-settings" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the group.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the group. `meeting_security`: Use this query parameter to view meeting security settings applied on the group. (allows empty value)
]: nothing -> any {
  http-request {
    method: get
    path: "/groups/{groupId}/settings"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: custom_query_fields, var: custom_query_fields}, {name: option, var: option}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, custom_query_fields: $custom_query_fields, option: $option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a group's settings
#
# PATCH /groups/{groupId}/settings
# operationId: updateGroupSettings
export def "update-group-settings" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
  --option: string@option-completer-2 # allows empty value
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, cloud_recording_available_reminder?: bool, jbh_reminder?: bool, schedule_for_host_reminder?: bool}
  --in-meeting: record # shape: {alert_guest_join?: bool, allow_show_zoom_windows?: bool, annotation?: bool, attendee_on_hold?: bool, auto_answer?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, data_center_regions?: "EU"|"HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA", e2e_encryption?: bool, entry_exit_chime?: string, far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, group_hd?: bool, non_verbal_feedback?: bool, ... (21 more fields)}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # shape: {account_user_access_recording?: bool, archive?: record, auto_recording?: string, cloud_recording?: bool, cloud_recording_download?: bool, cloud_recording_download_host?: bool, host_delete_cloud_recording?: bool, ip_address_access_control?: record, local_recording?: bool, prevent_host_access_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, save_chat_text?: bool, show_timestamp?: bool}
  --schedule-meeting: record # shape: {audio_type?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, mute_upon_entry?: bool, participant_video?: bool, pstn_password_protected?: bool, require_password_for_all_meetings?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "all"|"jbh_only"|"none", require_password_for_scheduled_meetings?: bool, require_password_for_scheduling_new_meetings?: bool, upcoming_meeting_reminder?: bool}
  --telephony: record # shape: {audio_conference_info?: string, third_party_audio?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/groups/{groupId}/settings"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: custom_query_fields, var: custom_query_fields}, {name: option, var: option}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_notification, var: email_notification}, {name: in_meeting, var: in_meeting}, {name: profile, var: profile}, {name: recording, var: recording}, {name: schedule_meeting, var: schedule_meeting}, {name: telephony, var: telephony}, {name: meeting_security, var: meeting_security}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    group_id: $group_id, custom_query_fields: $custom_query_fields, option: $option, email_notification: $email_notification, in_meeting: $in_meeting, profile: $profile, recording: $recording, schedule_meeting: $schedule_meeting, telephony: $telephony, meeting_security: $meeting_security
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete virtual background files
#
# DELETE /groups/{groupId}/settings/virtual_backgrounds
# operationId: delGroupVB
export def "del-group-vb" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  http-request {
    method: delete
    path: "/groups/{groupId}/settings/virtual_backgrounds"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: file_ids, var: file_ids}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, file_ids: $file_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload virtual background files
#
# POST /groups/{groupId}/settings/virtual_backgrounds
# Returns: record<id: string, is_default: bool, name: string, size: string, type: string>
# operationId: uploadGroupVB
export def "upload-group-vb" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
  --file: string # Provide the file's path here.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{groupId}/settings/virtual_backgrounds"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: file_ids, var: file_ids}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    group_id: $group_id, file_ids: $file_ids, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List H.323/SIP devices
#
# GET /h323/devices
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, devices: table<id: string, encryption: string, ip: string, name: string, protocol: string>>
# operationId: deviceList
export def "device-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/h323/devices"
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a H.323/SIP device
#
# POST /h323/devices
# Returns: record<id: string, encryption: string, ip: string, name: string, protocol: string>
# operationId: deviceCreate
export def "device-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  encryption: string@encryption-completer # Device encryption:`auto` - auto.`yes` - yes.`no` - no.
  ip: string # Device IP.
  name: string # Device name.
  protocol: string@protocol-completer # Device protocol:`H.323` - H.323.`SIP` - SIP.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/h323/devices"
    body: {content_type: "application/json", kind: json, fields: [{name: encryption, var: encryption}, {name: ip, var: ip}, {name: name, var: name}, {name: protocol, var: protocol}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: bearer
  } {
    encryption: $encryption, ip: $ip, name: $name, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a H.323/SIP device
#
# DELETE /h323/devices/{deviceId}
# operationId: deviceDelete
export def "device-delete" [
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
    method: delete
    path: "/h323/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a H.323/SIP device
#
# PATCH /h323/devices/{deviceId}
# operationId: deviceUpdate
export def "device-update" [
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
  encryption: string@encryption-completer # Device encryption:`auto` - auto.`yes` - yes.`no` - no.
  ip: string # Device IP.
  name: string # Device name.
  protocol: string@protocol-completer # Device protocol:`H.323` - H.323.`SIP` - SIP.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/h323/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryption, var: encryption}, {name: ip, var: ip}, {name: name, var: name}, {name: protocol, var: protocol}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    device_id: $device_id, encryption: $encryption, ip: $ip, name: $name, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send chatbot messages
#
# POST /im/chat/messages
# operationId: sendchatbot
export def "sendchatbot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # Account ID of the authorized account.
  content: record # JSON template describing how the message should be displayed for the user. For more information please see our ["Send Message" templates](https://marketplace.zoom.us/docs/guides/chatbots/sending-messages#example-request).
  --is-markdown-support: oneof<nothing, bool> # **Optional** Applies the markdown parser to your chatbot message if the value of this field is set to `true`. To learn more, refer to the Chatbot message [markdown reference](https://marketplace.zoom.us/docs/guides/chatbots/customizing-messages/message-with-markdown).
  robot_jid: string # Robot JID created when enabling chatbot features on your marketplace app.
  to_jid: string # Unique JID of reciever. Can be a group or user.
  --user-jid: string # **Optional** The UserJID of the user on whose behalf the message is being sent. Use this field to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
  --visible-to-user: string # **Optional**Allow a Chatbot to send a message to a group channel, but have only one designated person in that group channel see the message by providing the person's UserID in this field.
]: any -> any {
  $in | http-request {
    method: post
    path: "/im/chat/messages"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: content, var: content}, {name: is_markdown_support, var: is_markdown_support}, {name: robot_jid, var: robot_jid}, {name: to_jid, var: to_jid}, {name: user_jid, var: user_jid}, {name: visible_to_user, var: visible_to_user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, content: $content, is_markdown_support: $is_markdown_support, robot_jid: $robot_jid, to_jid: $to_jid, user_jid: $user_jid, visible_to_user: $visible_to_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a chatbot message
#
# DELETE /im/chat/messages/{message_id}
# Returns: record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string>
# operationId: deleteAChatbotMessage
export def "delete-a-chatbot-message" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_id: string # The AccountID of the Zoom account to which the message was sent. Retrieve this from the Chatbot request sent to your server as shown in the example [here]( https://marketplace.zoom.us/docs/guides/chatbots/sending-messages).
  robot_jid: string # The BotJID found in the Chat Subscription Section on the Features page of your App Dashboard.
  --user-jid: string # The UserJID of the user on whose behalf the message is being sent. Used to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/im/chat/messages/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: robot_jid, var: robot_jid}, {name: user_jid, var: user_jid}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id, account_id: $account_id, robot_jid: $robot_jid, user_jid: $user_jid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Edit a chatbot message
#
# PUT /im/chat/messages/{message_id}
# Returns: record<message_id: string, robot_jid: string, sent_time: string, to_jid: string, user_jid: string>
# operationId: editChatbotMessage
export def "edit-chatbot-message" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  account_id: string # The AccountID of the Zoom account to which the message was sent. Retrieve this from the Chatbot request sent to your server as shown in the example [here]( https://marketplace.zoom.us/docs/guides/chatbots/sending-messages).
  content: record # JSON template describing how the edited message should be displayed for the user. For more information please see our ["Send Message" templates](https://marketplace.zoom.us/docs/guides/chatbots/sending-messages#example-request).
  --is-markdown-support: oneof<nothing, bool> # **Optional** Enable or disable markdown parser to your chatbot message. Applies the markdown parser to your chatbot message if the value of this field is set to `true`. To learn more, refer to the Chatbot message [markdown reference](https://marketplace.zoom.us/docs/guides/chatbots/customizing-messages/message-with-markdown).
  robot_jid: string # Robot JID created when enabling chatbot features on your marketplace app.
  --user-jid: string # **Optional** The UserJID of the user on whose behalf the message is being sent. Use this field to prevent members of a channel from getting notifications that were set up by a user who has left the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/im/chat/messages/{message_id}"
    path_params: [{name: message_id, var: message_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: content, var: content}, {name: is_markdown_support, var: is_markdown_support}, {name: robot_jid, var: robot_jid}, {name: user_jid, var: user_jid}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id, account_id: $account_id, content: $content, is_markdown_support: $is_markdown_support, robot_jid: $robot_jid, user_jid: $user_jid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get IM chat sessions
#
# GET /im/chat/sessions
# DEPRECATED
# Returns: record<from: string, to: string, next_page_token: string, page_size: int, sessions: table<last_message_sent_time: string, name: string, session_id: string, type: string>>
# operationId: imChatSessions
@deprecated
export def "im-chat-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/im/chat/sessions"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get IM chat messages
#
# GET /im/chat/sessions/{sessionId}
# DEPRECATED
# Returns: record<from: string, session_id: string, to: string, next_page_token: string, page_size: int, messages: table<action: string, action_time: string, date_time: string, message: string, sender: string>>
# operationId: imChatMessages
@deprecated
export def "im-chat-messages" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/im/chat/sessions/{sessionId}"
    path_params: [{name: sessionId, var: session_id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    session_id: $session_id, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List IM directory groups
#
# GET /im/groups
# Returns: record<total_records: int, groups: table<id: string, name: string, total_members: int, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, type: string>>
# operationId: imGroups
export def "im-groups" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/im/groups"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create an IM directory group
#
# POST /im/groups
# Returns: record<id: string, name: string, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, total_members: int>
# operationId: imGroupCreate
export def "im-group-create" [
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
  --name: string # Group name: must be unique to one account.
  --search-by-account: oneof<nothing, bool> # Members can search for others under same account.
  --search-by-domain: oneof<nothing, bool> # Members can search for others in the same email domain.
  --search-by-ma-account: oneof<nothing, bool> # Members can search for others under same master account, including all sub accounts.
  --type: string@type-completer-1 # IM Group types:`normal` - Only members can see automatically see the other members of this group. Other people can search for members within this group. `shared` - Everyone under an account can see the group members automatically.`restricted` - Nobody can see the group or search for members except the members in the group. (default: normal)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/im/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: search_by_account, var: search_by_account}, {name: search_by_domain, var: search_by_domain}, {name: search_by_ma_account, var: search_by_ma_account}, {name: type, var: type}]}
    accept: ["application/json", "application/xml", new]
    ok: [200, 201]
    auth: bearer
  } {
    name: $name, search_by_account: $search_by_account, search_by_domain: $search_by_domain, search_by_ma_account: $search_by_ma_account, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an IM directory group
#
# DELETE /im/groups/{groupId}
# operationId: imGroupDelete
export def "im-group-delete" [
  group_id: string
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
    path: "/im/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an IM directory group
#
# GET /im/groups/{groupId}
# Returns: record<id: string, name: string, total_members: int, search_by_account: bool, search_by_domain: bool, search_by_ma_account: bool, type: string>
# operationId: imGroup
export def "im-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/im/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update an IM directory group
#
# PATCH /im/groups/{groupId}
# operationId: imGroupUpdate
export def "im-group-update" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Group name: must be unique to one account.
  --search-by-account: oneof<nothing, bool> # Members can search for others under same account.
  --search-by-domain: oneof<nothing, bool> # Members can search for others in the same email domain.
  --search-by-ma-account: oneof<nothing, bool> # Members can search for others under same master account, including all sub accounts.
  --type: string@type-completer-1 # IM Group types:`normal` - Only group members can automatically see others in their group. Other people can search for members in the group.`shared` - Everyone under the account can see the group and members automatically.`restricted` - Nobody can see the group or search for members except for the members in the group.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/im/groups/{groupId}"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: search_by_account, var: search_by_account}, {name: search_by_domain, var: search_by_domain}, {name: search_by_ma_account, var: search_by_ma_account}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    group_id: $group_id, name: $name, search_by_account: $search_by_account, search_by_domain: $search_by_domain, search_by_ma_account: $search_by_ma_account, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List IM directory group members
#
# GET /im/groups/{groupId}/members
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, members: table<email: string, first_name: string, id: string, last_name: string, type: int>>
# operationId: imGroupMembers
export def "im-group-members" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/im/groups/{groupId}/members"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    group_id: $group_id, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add IM directory group members
#
# POST /im/groups/{groupId}/members
# Returns: record<added_at: string, ids: string>
# operationId: imGroupMembersCreate
export def "im-group-members-create" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # List of IM group members. — item shape: {email?: string, id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/im/groups/{groupId}/members"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 300]
    auth: bearer
  } {
    group_id: $group_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an IM directory group member
#
# DELETE /im/groups/{groupId}/members/{memberId}
# operationId: imGroupMembersDelete
export def "im-group-members-delete" [
  group_id: string
  member_id: string
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
    path: "/im/groups/{groupId}/members/{memberId}"
    path_params: [{name: groupId, var: group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    group_id: $group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send IM messages
#
# POST /im/users/me/chat/messages
# DEPRECATED
# Returns: record<id: string>
# operationId: sendimmessages
@deprecated
export def "sendimmessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --chat-user: string # The email address (registered with Zoom) or the userId of the chat user.
  --message: string # IM message content.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/im/users/me/chat/messages"
    query: [{name: chat_user, var: chat_user}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    chat_user: $chat_user, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user’s IM messages
#
# GET /im/users/{userId}/chat/messages
# DEPRECATED
# Returns: record<date: string, messages: table<date_time: string, id: string, message: string, sender: string, timstamp: int>, next_page_token: string, page_size: int>
# operationId: listimmessages
@deprecated
export def "listimmessages" [
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
  --chat-user: string # Chat user's ID or email address.
  --channel: string # IM Channel's ID.
  --date: string # IM message's query date time, format as yyyy-MM-dd.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/im/users/{userId}/chat/messages"
    path_params: [{name: userId, var: user_id}]
    query: [{name: chat_user, var: chat_user}, {name: channel, var: channel}, {name: date, var: date}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, chat_user: $chat_user, channel: $channel, date: $date, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Use in-Meeting recording controls
#
# PATCH /live_meetings/{meetingId}/events
# operationId: inMeetingRecordingControl
export def "in-meeting-recording-control" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --method: string # The method that you would like to control. The value of this field can be one of the following: * `recording.start`: Provide this value if you would like to start the recording. * `recording.stop`: Provide this value if you would like to stop the recording. * `recording.pause`: Provide this value if you would like to pause the recording. * `recording.resume`: Provide this value if you would like to resume the recording that was previously paused.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/live_meetings/{meetingId}/events"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: method, var: method}]}
    accept: ["application/json", "application/xml"]
    ok: [202]
    auth: bearer
  } {
    meeting_id: $meeting_id, method: $method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a meeting
#
# DELETE /meetings/{meetingId}
# operationId: meetingDelete
export def "meeting-delete" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  --schedule-for-reminder: oneof<nothing, bool> # `true`: Notify host and alternative host about the meeting cancellation via email. `false`: Do not send any email notification.
  --cancel-meeting-reminder: string # `true`: Notify registrants about the meeting cancellation via email. `false`: Do not send any email notification to meeting registrants. The default value of this field is `false`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: schedule_for_reminder, var: schedule_for_reminder}, {name: cancel_meeting_reminder, var: cancel_meeting_reminder}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_id: $occurrence_id, schedule_for_reminder: $schedule_for_reminder, cancel_meeting_reminder: $cancel_meeting_reminder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a meeting
#
# GET /meetings/{meetingId}
# Returns: record<assistant_id: string, host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, encrypted_password: string, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, status: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int>
# operationId: meeting
export def "meeting" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # Meeting Occurrence ID. Provide this field to view meeting details of a particular occurrence of the [recurring meeting](https://support.zoom.us/hc/en-us/articles/214973206-Scheduling-Recurring-Meetings).
  --show-previous-occurrences: oneof<nothing, bool> # Set the value of this field to `true` if you would like to view meeting details of all previous occurrences of a [recurring meeting](https://support.zoom.us/hc/en-us/articles/214973206-Scheduling-Recurring-Meetings).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: show_previous_occurrences, var: show_previous_occurrences}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_id: $occurrence_id, show_previous_occurrences: $show_previous_occurrences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a meeting
#
# PATCH /meetings/{meetingId}
# operationId: meetingUpdate
export def "meeting-update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # Meeting occurrence id. Support change of agenda, start_time, duration, settings: {host_video, participant_video, join_before_host, mute_upon_entry, waiting_room, watermark, auto_recording}
  --schedule-for: string # Email or userId if you want to schedule meeting for another user.
  --agenda: string # Meeting description.
  --duration: int # Meeting duration (minutes). Used for scheduled meetings only.
  --password: string # Meeting passcode. Passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ *] and can have a maximum of 10 characters. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recurrence: record # Recurrence object. Use this object only for a meeting with type `8` i.e., a recurring meeting with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
  --settings: record # Meeting settings. — shape: {allow_multiple_devices?: bool, alternative_hosts?: string, alternative_hosts_email_notification?: bool, approval_type?: "0"|"1"|"2", approved_or_denied_countries_or_regions?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_exception?: list, authentication_name?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", breakout_room?: record, close_registration?: bool, cn_meeting?: bool, contact_email?: string, ... (22 more fields)}
  --start-time: string # Meeting start time. When using a format like "yyyy-MM-dd'T'HH:mm:ss'Z'", always use GMT time. When using a format like "yyyy-MM-dd'T'HH:mm:ss", you should use local time and specify the time zone. Only used for scheduled meetings and recurring meetings with a fixed time. (format: date-time)
  --template-id: string # Unique identifier of the meeting template. Use this field if you would like to [schedule the meeting from a meeting template](https://support.zoom.us/hc/en-us/articles/360036559151-Meeting-templates#h_86f06cff-0852-4998-81c5-c83663c176fb). You can retrieve the value of this field by calling the [List meeting templates]() API.
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [time zone](#timezones) list for supported time zones and their formats.
  --topic: string # Meeting topic.
  --tracking-fields: list # Tracking fields — item shape: {field?: string, value?: string}
  --type: int@type-completer-2 # Meeting Types:`1` - Instant meeting.`2` - Scheduled meeting.`3` - Recurring meeting with no fixed time.`8` - Recurring meeting with a fixed time. (default: 2)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: schedule_for, var: schedule_for}, {name: agenda, var: agenda}, {name: duration, var: duration}, {name: password, var: password}, {name: recurrence, var: recurrence}, {name: settings, var: settings}, {name: start_time, var: start_time}, {name: template_id, var: template_id}, {name: timezone, var: timezone}, {name: topic, var: topic}, {name: tracking_fields, var: tracking_fields}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_id: $occurrence_id, schedule_for: $schedule_for, agenda: $agenda, duration: $duration, password: $password, recurrence: $recurrence, settings: $settings, start_time: $start_time, template_id: $template_id, timezone: $timezone, topic: $topic, tracking_fields: $tracking_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform batch poll creation
#
# POST /meetings/{meetingId}/batch_polls
# Returns: record<polls: table<id: string, questions: list, status: string, title: string>>
# operationId: createBatchPolls
export def "create-batch-polls" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Meeting Poll Title.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/batch_polls"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: questions, var: questions}, {name: title, var: title}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, questions: $questions, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting invitation
#
# GET /meetings/{meetingId}/invitation
# Returns: record<invitation: string>
# operationId: meetingInvitation
export def "meeting-invitation" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/invitation"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get live stream details
#
# GET /meetings/{meetingId}/livestream
# Returns: record<page_url: string, stream_key: string, stream_url: string>
# operationId: getLiveStreamDetails
export def "get-live-stream-details" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/livestream"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a live stream
#
# PATCH /meetings/{meetingId}/livestream
# operationId: meetingLiveStreamUpdate
export def "meeting-live-stream-update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-url: string # The livestream page URL. (format: uri)
  stream_key: string # Stream name and key.
  stream_url: string # Streaming URL.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}/livestream"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: page_url, var: page_url}, {name: stream_key, var: stream_key}, {name: stream_url, var: stream_url}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, page_url: $page_url, stream_key: $stream_key, stream_url: $stream_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Live Stream Status
#
# PATCH /meetings/{meetingId}/livestream/status
# operationId: meetingLiveStreamStatusUpdate
export def "meeting-live-stream-status-update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # Update the status of a livestream. The value can be one of the following: `start`: Start a live stream. `stop`: Stop an ongoing live stream.
  --settings: record # Update the settings of a live streaming session. The settings can only be updated for a live stream that has been stopped. You can not update the settings of an ongoing live stream. — shape: {active_speaker_name?: bool, display_name?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}/livestream/status"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: settings, var: settings}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, action: $action, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List meeting polls
#
# GET /meetings/{meetingId}/polls
# Returns: record<polls: table<id: string, status: string, questions: list, title: string>, total_records: int>
# operationId: meetingPolls
export def "meeting-polls" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/polls"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a meeting poll
#
# POST /meetings/{meetingId}/polls
# Returns: record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>
# operationId: meetingPollCreate
export def "meeting-poll-create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/polls"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: questions, var: questions}, {name: title, var: title}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, questions: $questions, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a meeting poll
#
# DELETE /meetings/{meetingId}/polls/{pollId}
# operationId: meetingPollDelete
export def "meeting-poll-delete" [
  meeting_id: int
  poll_id: string
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
    path: "/meetings/{meetingId}/polls/{pollId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: pollId, var: poll_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, poll_id: $poll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a meeting poll
#
# GET /meetings/{meetingId}/polls/{pollId}
# Returns: record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>
# operationId: meetingPollGet
export def "meeting-poll-get" [
  meeting_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/polls/{pollId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: pollId, var: poll_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, poll_id: $poll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a meeting poll
#
# PUT /meetings/{meetingId}/polls/{pollId}
# operationId: meetingPollUpdate
export def "meeting-poll-update" [
  meeting_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/polls/{pollId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: pollId, var: poll_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: questions, var: questions}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, poll_id: $poll_id, questions: $questions, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete meeting recordings
#
# DELETE /meetings/{meetingId}/recordings
# operationId: recordingDelete
export def "recording-delete" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # The recording delete actions:`trash` - Move recording to trash.`delete` - Delete recording permanently. (default: trash)
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}/recordings"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: action, var: action}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    meeting_id: $meeting_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get meeting recordings
#
# GET /meetings/{meetingId}/recordings
# Returns: record<account_id: string, duration: int, host_id: string, id: string, recording_count: string, start_time: string, topic: string, total_size: string, type: string, uuid: string, recording_files: table<deleted_time: string, download_url: string, file_size: float, file_type: string, id: string, meeting_id: string, play_url: string, recording_end: string, recording_start: string, recording_type: string, status: string>, download_access_token: string>
# operationId: recordingGet
export def "recording-get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-fields: string # Get the `download_access_token` field for downloading meeting recordings.
  --ttl: int # Time to live (TTL) of the `download_access_token`. This is only valid if the `include_fields` query parameter contains `download_access_token`. The range is between 0-604800.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/meetings/{meetingId}/recordings"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: include_fields, var: include_fields}, {name: ttl, var: ttl}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, include_fields: $include_fields, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List recording registrants
#
# GET /meetings/{meetingId}/recordings/registrants
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string>>
# operationId: meetingRecordingRegistrants
export def "meeting-recording-registrants" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/meetings/{meetingId}/recordings/registrants"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: status, var: status}, {name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, status: $status, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a recording registrant
#
# POST /meetings/{meetingId}/recordings/registrants
# Returns: record<id: int, registrant_id: string, share_url: string, topic: string>
# operationId: meetingRecordingRegistrantCreate
export def "meeting-recording-registrant-create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/recordings/registrants"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: comments, var: comments}, {name: country, var: country}, {name: custom_questions, var: custom_questions}, {name: email, var: email}, {name: first_name, var: first_name}, {name: industry, var: industry}, {name: job_title, var: job_title}, {name: last_name, var: last_name}, {name: no_of_employees, var: no_of_employees}, {name: org, var: org}, {name: phone, var: phone}, {name: purchasing_time_frame, var: purchasing_time_frame}, {name: role_in_purchase_process, var: role_in_purchase_process}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    meeting_id: $meeting_id, address: $address, city: $city, comments: $comments, country: $country, custom_questions: $custom_questions, email: $email, first_name: $first_name, industry: $industry, job_title: $job_title, last_name: $last_name, no_of_employees: $no_of_employees, org: $org, phone: $phone, purchasing_time_frame: $purchasing_time_frame, role_in_purchase_process: $role_in_purchase_process, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get registration questions
#
# GET /meetings/{meetingId}/recordings/registrants/questions
# Returns: record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>
# operationId: recordingRegistrantsQuestionsGet
export def "recording-registrants-questions-get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/recordings/registrants/questions"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update registration questions
#
# PATCH /meetings/{meetingId}/recordings/registrants/questions
# operationId: recordingRegistrantQuestionUpdate
export def "recording-registrant-question-update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"|"multiple"}
  --questions: list # Array of Registrant Questions — item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}/recordings/registrants/questions"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_questions, var: custom_questions}, {name: questions, var: questions}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, custom_questions: $custom_questions, questions: $questions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update registrant's status
#
# PUT /meetings/{meetingId}/recordings/registrants/status
# operationId: meetingRecordingRegistrantStatus
export def "meeting-recording-registrant-status" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer-4
  --registrants: list # List of registrants — item shape: {id?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/recordings/registrants/status"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: registrants, var: registrants}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, action: $action, registrants: $registrants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get meeting recording settings
#
# GET /meetings/{meetingId}/recordings/settings
# Returns: record<approval_type: int, authentication_domains: string, authentication_option: string, on_demand: bool, password: string, recording_authentication: bool, send_email_to_host: bool, share_recording: string, show_social_share_buttons: bool, topic: string, viewer_download: bool>
# operationId: recordingSettingUpdate
export def "recording-setting-update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/recordings/settings"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update meeting recording settings
#
# PATCH /meetings/{meetingId}/recordings/settings
# operationId: recordingSettingsUpdate
export def "recording-settings-update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --approval-type: int@approval-type-completer # Approval type for the registration. `0`- Automatically approve the registration when a user registers. `1` - Manually approve or deny the registration of a user. `2` - No registration required to view the recording.
  --authentication-domains: string # Authentication domains.
  --authentication-option: string # Authentication Options.
  --on-demand: oneof<nothing, bool> # Determine whether registration isrequired to view the recording.
  --password: string # Enable password protection for the recording by setting a password. The password must have a minimum of **eight** characters with a mix of numbers, letters and special characters. **Note:** If the account owner or the admin has set minimum password strength requirements for recordings via Account Settings, the password value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recording-authentication: oneof<nothing, bool> # Only authenticated users can view.
  --send-email-to-host: oneof<nothing, bool> # Send an email to host when someone registers to view the recording. This applies for On-demand recordings only.
  --share-recording: string@share-recording-completer # Determine how the meeting recording is shared.
  --show-social-share-buttons: oneof<nothing, bool> # Show social share buttons on registration page. This applies for On-demand recordings only.
  --topic: string # Name of the recording.
  --viewer-download: oneof<nothing, bool> # Determine whether a viewer can download the recording file or not.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}/recordings/settings"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: approval_type, var: approval_type}, {name: authentication_domains, var: authentication_domains}, {name: authentication_option, var: authentication_option}, {name: on_demand, var: on_demand}, {name: password, var: password}, {name: recording_authentication, var: recording_authentication}, {name: send_email_to_host, var: send_email_to_host}, {name: share_recording, var: share_recording}, {name: show_social_share_buttons, var: show_social_share_buttons}, {name: topic, var: topic}, {name: viewer_download, var: viewer_download}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, approval_type: $approval_type, authentication_domains: $authentication_domains, authentication_option: $authentication_option, on_demand: $on_demand, password: $password, recording_authentication: $recording_authentication, send_email_to_host: $send_email_to_host, share_recording: $share_recording, show_social_share_buttons: $show_social_share_buttons, topic: $topic, viewer_download: $viewer_download
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover meeting recordings
#
# PUT /meetings/{meetingId}/recordings/status
# operationId: recordingStatusUpdate
export def "recording-status-update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/recordings/status"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    meeting_id: $meeting_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a meeting recording file
#
# DELETE /meetings/{meetingId}/recordings/{recordingId}
# operationId: recordingDeleteOne
export def "recording-delete-one" [
  meeting_id: string
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # The recording delete actions:`trash` - Move recording to trash.`delete` - Delete recording permanently. (default: trash)
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}/recordings/{recordingId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: recordingId, var: recording_id}]
    query: [{name: action, var: action}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    meeting_id: $meeting_id, recording_id: $recording_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover a single recording
#
# PUT /meetings/{meetingId}/recordings/{recordingId}/status
# operationId: recordingStatusUpdateOne
export def "recording-status-update-one" [
  meeting_id: string
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/recordings/{recordingId}/status"
    path_params: [{name: meetingId, var: meeting_id}, {name: recordingId, var: recording_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, recording_id: $recording_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List meeting registrants
#
# GET /meetings/{meetingId}/registrants
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>
# operationId: meetingRegistrants
export def "meeting-registrants" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/meetings/{meetingId}/registrants"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: status, var: status}, {name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_id: $occurrence_id, status: $status, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add meeting registrant
#
# POST /meetings/{meetingId}/registrants
# Returns: record<id: int, join_url: string, registrant_id: string, start_time: string, topic: string>
# operationId: meetingRegistrantCreate
export def "meeting-registrant-create" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-ids: string # Occurrence IDs. You can find these with the meeting get API. Multiple values separated by comma.
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
  --language: string # Registrant's language preference for confirmation emails. The value can be one of the following: `en-US`,`de-DE`,`es-ES`,`fr-FR`,`jp-JP`,`pt-PT`,`ru-RU`,`zh-CN`, `zh-TW`, `ko-KO`, `it-IT`, `vi-VN`.
  --auto-approve: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/meetings/{meetingId}/registrants"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_ids, var: occurrence_ids}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: comments, var: comments}, {name: country, var: country}, {name: custom_questions, var: custom_questions}, {name: email, var: email}, {name: first_name, var: first_name}, {name: industry, var: industry}, {name: job_title, var: job_title}, {name: last_name, var: last_name}, {name: no_of_employees, var: no_of_employees}, {name: org, var: org}, {name: phone, var: phone}, {name: purchasing_time_frame, var: purchasing_time_frame}, {name: role_in_purchase_process, var: role_in_purchase_process}, {name: state, var: state}, {name: zip, var: zip}, {name: language, var: language}, {name: auto_approve, var: auto_approve}]}
    accept: ["application/json", "application/xml"]
    ok: [201, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_ids: $occurrence_ids, address: $address, city: $city, comments: $comments, country: $country, custom_questions: $custom_questions, email: $email, first_name: $first_name, industry: $industry, job_title: $job_title, last_name: $last_name, no_of_employees: $no_of_employees, org: $org, phone: $phone, purchasing_time_frame: $purchasing_time_frame, role_in_purchase_process: $role_in_purchase_process, state: $state, zip: $zip, language: $language, auto_approve: $auto_approve
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List registration questions
#
# GET /meetings/{meetingId}/registrants/questions
# Returns: record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>
# operationId: meetingRegistrantsQuestionsGet
export def "meeting-registrants-questions-get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/meetings/{meetingId}/registrants/questions"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update registration questions
#
# PATCH /meetings/{meetingId}/registrants/questions
# operationId: meetingRegistrantQuestionUpdate
export def "meeting-registrant-question-update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single"}
  --questions: list # Array of Registrant Questions — item shape: {field_name?: "address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/meetings/{meetingId}/registrants/questions"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_questions, var: custom_questions}, {name: questions, var: questions}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, custom_questions: $custom_questions, questions: $questions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update registrant's status
#
# PUT /meetings/{meetingId}/registrants/status
# operationId: meetingRegistrantStatus
export def "meeting-registrant-status" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  action: string@action-completer-6 # Registrant Status:`approve` - Approve registrant.`cancel` - Cancel previously approved registrant's registration.`deny` - Deny registrant.
  --registrants: list # List of registrants. — item shape: {email?: string, id?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/registrants/status"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: registrants, var: registrants}]}
    accept: ["application/json"]
    ok: [204, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, occurrence_id: $occurrence_id, action: $action, registrants: $registrants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a meeting registrant
#
# DELETE /meetings/{meetingId}/registrants/{registrantId}
# operationId: meetingregistrantdelete
export def "meetingregistrantdelete" [
  meeting_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurence ID.
]: nothing -> any {
  http-request {
    method: delete
    path: "/meetings/{meetingId}/registrants/{registrantId}"
    path_params: [{name: meetingId, var: meeting_id}, {name: registrantId, var: registrant_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, registrant_id: $registrant_id, occurrence_id: $occurrence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update meeting status
#
# PUT /meetings/{meetingId}/status
# operationId: meetingStatus
export def "meeting-status" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7 # `end` - End a meeting. `recover` - [Recover](https://support.zoom.us/hc/en-us/articles/360038297111-Recover-a-deleted-meeting) a deleted meeting.
]: any -> any {
  $in | http-request {
    method: put
    path: "/meetings/{meetingId}/status"
    path_params: [{name: meetingId, var: meeting_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    meeting_id: $meeting_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Zoom meetings client feedback
#
# GET /metrics/client/feedback
# Returns: record<client_feedbacks: table<feedback_id: string, feedback_name: string, participants_count: int>, from: string, to: string, total_records: int>
# operationId: dashboardClientFeedback
export def "dashboard-client-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/client/feedback"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get zoom meetings client feedback
#
# GET /metrics/client/feedback/{feedbackId}
# Returns: record<from: string, to: string, next_page_token: string, page_size: int, client_feedback_details: table<email: string, meeting_id: string, participant_name: string, time: string>>
# operationId: dashboardClientFeedbackDetail
export def "dashboard-client-feedback-detail" [
  feedback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # format: date
  --to: string # format: date
  --page-size: int # default: 30
  --next-page-token: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/client/feedback/{feedbackId}"
    path_params: [{name: feedbackId, var: feedback_id}]
    query: [{name: from, var: from}, {name: to, var: to}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    feedback_id: $feedback_id, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List client meeting satisfaction
#
# GET /metrics/client/satisfaction
# Returns: record<client_satisfaction: table<date: string, good_count: int, none_count: int, not_good_count: int, satisfaction_percent: int>, from: string, to: string, total_records: int>
# operationId: listMeetingSatisfaction
export def "list-meeting-satisfaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # The start date for the query in “yyyy-mm-dd” format. (format: date)
  --to: string # The end date for the query in “yyyy-mm-dd” format. (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/client/satisfaction"
    query: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get CRC port usage
#
# GET /metrics/crc
# Returns: record<from: string, to: string, crc_ports_usage: table<crc_ports_hour_usage: list, date_time: string>>
# operationId: dashboardCRC
export def "dashboard-crc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/crc"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get IM metrics
#
# GET /metrics/im
# Returns: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, users: table<calls_receive: int, calls_send: int, email: string, emoji_receive: int, emoji_send: int, files_receive: int, files_send: int, group_receive: int, group_send: int, images_receive: int, images_send: int, total_receive: int, total_send: int, user_id: string, user_name: string, videos_receive: int, videos_send: int, voice_receive: int, voice_send: int>>
# operationId: dashboardIM
export def "dashboard-im" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/im"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 25 Zoom Rooms with issues
#
# GET /metrics/issues/zoomrooms
# Returns: record<from: string, to: string, total_records: int, zoom_rooms: table<id: string, issues_count: int, room_name: string>>
# operationId: dashboardIssueZoomRoom
export def "dashboard-issue-zoom-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/issues/zoomrooms"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get issues of Zoom Rooms
#
# GET /metrics/issues/zoomrooms/{zoomroomId}
# Returns: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, issue_details: table<issue: string, time: string>>
# operationId: dashboardIssueDetailZoomRoom
export def "dashboard-issue-detail-zoom-room" [
  zoomroom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/issues/zoomrooms/{zoomroomId}"
    path_params: [{name: zoomroomId, var: zoomroom_id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    zoomroom_id: $zoomroom_id, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List meetings
#
# GET /metrics/meetings
# Returns: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, tracking_fields: list, user_type: string, uuid: string>>
# operationId: dashboardMeetings
export def "dashboard-meetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer # Set the value of this field to "tracking_fields" if you would like to include tracking fields of each meeting in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings"
    query: [{name: type, var: type}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_fields, var: include_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    type: $type, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting details
#
# GET /metrics/meetings/{meetingId}
# Returns: record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>
# operationId: dashboardMeetingDetail
export def "dashboard-meeting-detail" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings.`live` - Live meetings. (default: live)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List meeting participants
#
# GET /metrics/meetings/{meetingId}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, camera: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, in_room_participants: int, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, status: string, user_id: string, user_name: string, version: string, video_quality: string>>
# operationId: dashboardMeetingParticipants
export def "dashboard-meeting-participants" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings.`live` - Live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide `registrant_id` as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [meeting registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingregistrants). This is not supported for `live` meeting types.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}/participants"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_fields, var: include_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, type: $type, page_size: $page_size, next_page_token: $next_page_token, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List meeting participants QoS
#
# GET /metrics/meetings/{meetingId}/participants/qos
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: list, version: string>>
# operationId: dashboardMeetingParticipantsQOS
export def "dashboard-meeting-participants-qos" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
  --page-size: int # The number of items returned per page. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}/participants/qos"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get post meeting feedback
#
# GET /metrics/meetings/{meetingId}/participants/satisfaction
# Returns: record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>>
# operationId: participantFeedback
export def "participant-feedback" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}/participants/satisfaction"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: type, var: type}, {name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id, type: $type, next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get sharing/recording details
#
# GET /metrics/meetings/{meetingId}/participants/sharing
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>>
# operationId: dashboardMeetingParticipantShare
export def "dashboard-meeting-participant-share" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceed the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}/participants/sharing"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting participant QoS
#
# GET /metrics/meetings/{meetingId}/participants/{participantId}/qos
# Returns: record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string>
# operationId: dashboardMeetingParticipantQOS
export def "dashboard-meeting-participant-qos" [
  meeting_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # The meeting types: `past` - Past meetings.`live` - Live Meetings. (default: live)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/meetings/{meetingId}/participants/{participantId}/qos"
    path_params: [{name: meetingId, var: meeting_id}, {name: participantId, var: participant_id}]
    query: [{name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, participant_id: $participant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List webinars
#
# GET /metrics/webinars
# Returns: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, webinars: table<custom_keys: list, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>>
# operationId: dashboardWebinars
export def "dashboard-webinars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars"
    query: [{name: type, var: type}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    type: $type, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar details
#
# GET /metrics/webinars/{webinarId}
# Returns: record<custom_keys: table<key: string, value: string>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>
# operationId: dashboardWebinarDetail
export def "dashboard-webinar-detail" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar participants
#
# GET /metrics/webinars/{webinarId}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<audio_quality: string, connection_type: string, customer_key: string, data_center: string, device: string, domain: string, email: string, harddisk_id: string, id: string, ip_address: string, join_time: string, leave_reason: string, leave_time: string, location: string, mac_addr: string, microphone: string, network_type: string, pc_name: string, recording: bool, registrant_id: string, screen_share_quality: string, share_application: bool, share_desktop: bool, share_whiteboard: bool, speaker: string, user_id: string, user_name: string, version: string, video_quality: string>>
# operationId: dashboardWebinarParticipants
export def "dashboard-webinar-participants" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide 'registrant_id' as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [webinar registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarregistrants).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}/participants"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_fields, var: include_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, type: $type, page_size: $page_size, next_page_token: $next_page_token, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List webinar participant QoS
#
# GET /metrics/webinars/{webinarId}/participants/qos
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: list, version: string>>
# operationId: dashboardWebinarParticipantsQOS
export def "dashboard-webinar-participants-qos" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
  --page-size: int # The number of items returned per page. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}/participants/qos"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get post webinar feedback
#
# GET /metrics/webinars/{webinarId}/participants/satisfaction
# Returns: record<next_page_token: string, page_size: int, participants: table<date_time: string, email: string, quality: string, user_id: string>>
# operationId: participantWebinarFeedback
export def "participant-webinar-feedback" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # Specify a value to get the response for the corresponding meeting type. The value of this field can be one of the following: `past` - Meeting that already occurred in the specified date range.`pastOne` - Past meetings that were attended by only one user. `live` - Live meetings. If you do not provide this field, the default value will be `live` and thus, the API will only query responses for live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}/participants/satisfaction"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get sharing/recording details
#
# GET /metrics/webinars/{webinarId}/participants/sharing
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<details: list, id: string, user_id: string, user_name: string>>
# operationId: dashboardWebinarParticipantShare
export def "dashboard-webinar-participant-share" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceed the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}/participants/sharing"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar participant QoS
#
# GET /metrics/webinars/{webinarId}/participants/{participantId}/qos
# Returns: record<device: string, domain: string, harddisk_id: string, ip_address: string, join_time: string, leave_time: string, location: string, mac_addr: string, pc_name: string, user_id: string, user_name: string, user_qos: table<as_device_from_crc: record, as_device_to_crc: record, as_input: record, as_output: record, audio_device_from_crc: record, audio_device_to_crc: record, audio_input: record, audio_output: record, cpu_usage: record, date_time: string, video_device_from_crc: record, video_device_to_crc: record, video_input: record, video_output: record>, version: string>
# operationId: dashboardWebinarParticipantQOS
export def "dashboard-webinar-participant-qos" [
  webinar_id: string
  participant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-4 # The webinar type. (default: live)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/webinars/{webinarId}/participants/{participantId}/qos"
    path_params: [{name: webinarId, var: webinar_id}, {name: participantId, var: participant_id}]
    query: [{name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, participant_id: $participant_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Zoom Rooms
#
# GET /metrics/zoomrooms
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, zoom_rooms: table<account_type: string, calender_name: string, camera: string, device_ip: string, email: string, health: string, id: string, issues: list, last_start_time: string, location: string, microphone: string, room_name: string, speaker: string, status: string>>
# operationId: dashboardZoomRooms
export def "dashboard-zoom-rooms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/zoomrooms"
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 25 issues of Zoom Rooms
#
# GET /metrics/zoomrooms/issues
# Returns: record<from: string, to: string, total_records: int, issues: table<issue_name: string, zoom_rooms_count: int>>
# operationId: dashboardZoomRoomIssue
export def "dashboard-zoom-room-issue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/zoomrooms/issues"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Rooms details
#
# GET /metrics/zoomrooms/{zoomroomId}
# Returns: record<account_type: string, calender_name: string, camera: string, device_ip: string, email: string, health: string, id: string, issues: list<string>, last_start_time: string, location: string, microphone: string, room_name: string, speaker: string, status: string, live_meeting: record<custom_keys: list<record>, dept: string, duration: string, email: string, end_time: string, has_3rd_party_audio: bool, has_pstn: bool, has_recording: bool, has_screen_share: bool, has_sip: bool, has_video: bool, has_voip: bool, host: string, id: int, in_room_participants: int, participants: int, start_time: string, topic: string, user_type: string, uuid: string>, past_meetings: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: list<record>>>
# operationId: dashboardZoomRoom
export def "dashboard-zoom-room" [
  zoomroom_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/zoomrooms/{zoomroomId}"
    path_params: [{name: zoomroomId, var: zoomroom_id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    zoomroom_id: $zoomroom_id, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List past meeting's files
#
# GET /past_meetings/{meetingId}/files
# Returns: record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int>
# operationId: listPastMeetingFiles
export def "list-past-meeting-files" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_meetings/{meetingId}/files"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List ended meeting instances
#
# GET /past_meetings/{meetingId}/instances
# Returns: record<meetings: table<start_time: string, uuid: string>>
# operationId: pastMeetings
export def "past-meetings" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_meetings/{meetingId}/instances"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List past meeting's poll results
#
# GET /past_meetings/{meetingId}/polls
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: listPastMeetingPolls
export def "list-past-meeting-polls" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_meetings/{meetingId}/polls"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get past meeting details
#
# GET /past_meetings/{meetingUUID}
# Returns: record<duration: int, end_time: string, host_id: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string>
# operationId: pastMeetingDetails
export def "past-meeting-details" [
  meeting_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_meetings/{meetingUUID}"
    path_params: [{name: meetingUUID, var: meeting_uuid}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_uuid: $meeting_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get past meeting participants
#
# GET /past_meetings/{meetingUUID}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<id: string, name: string, user_email: string>>
# operationId: pastMeetingParticipants
export def "past-meeting-participants" [
  meeting_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/past_meetings/{meetingUUID}/participants"
    path_params: [{name: meetingUUID, var: meeting_uuid}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_uuid: $meeting_uuid, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar absentees
#
# GET /past_webinars/{WebinarUUID}/absentees
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>
# operationId: webinarAbsentees
export def "webinar-absentees" [
  webinar_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/past_webinars/{WebinarUUID}/absentees"
    path_params: [{name: WebinarUUID, var: webinar_uuid}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_uuid: $webinar_uuid, occurrence_id: $occurrence_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List past webinar files
#
# GET /past_webinars/{webinarId}/files
# Returns: record<in_meeting_files: table<download_url: string, file_name: string, file_size: int>, total_records: int>
# operationId: listPastWebinarFiles
export def "list-past-webinar-files" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_webinars/{webinarId}/files"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List past webinar instances
#
# GET /past_webinars/{webinarId}/instances
# Returns: record<webinars: table<start_time: string, uuid: string>>
# operationId: pastWebinars
export def "past-webinars" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_webinars/{webinarId}/instances"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List webinar participants
#
# GET /past_webinars/{webinarId}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, participants: table<id: string, name: string, user_email: string>, total_records: int>
# operationId: listWebinarParticipants
export def "list-webinar-participants" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/past_webinars/{webinarId}/participants"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List past webinar poll results
#
# GET /past_webinars/{webinarId}/polls
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: listPastWebinarPollResults
export def "list-past-webinar-poll-results" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_webinars/{webinarId}/polls"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Q&A of past webinar
#
# GET /past_webinars/{webinarId}/qa
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: listPastWebinarQA
export def "list-past-webinar-qa" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/past_webinars/{webinarId}/qa"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an auto receptionist
#
# POST /phone/auto_receptionists
# Returns: record<extension_number: int, id: string, name: string>
# operationId: addAutoReceptionist
export def "add-auto-receptionist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  name: string # Provide a name to help identify the auto receptionist.
  --site-id: string # Unique identifier of the site where the auto receptionist is to be assigned. This field is required only if you have [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/auto_receptionists"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    name: $name, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update auto receptionist details
#
# PATCH /phone/auto_receptionists/{autoReceptionistId}
# operationId: updateAutoReceptionist
export def "update-auto-receptionist" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --extension-number: int # Extension number to be assigned to the auto receptionist. If site code is enabled, provide the short extension number instead.
  --name: string # Display name of the auto receptionist.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/auto_receptionists/{autoReceptionistId}"
    path_params: [{name: autoReceptionistId, var: auto_receptionist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: extension_number, var: extension_number}, {name: name, var: name}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    auto_receptionist_id: $auto_receptionist_id, extension_number: $extension_number, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign all phone numbers
#
# DELETE /phone/auto_receptionists/{autoReceptionistId}/phone_numbers
# operationId: unassignAllPhoneNumsAutoReceptionist
export def "unassign-all-phone-nums-auto-receptionist" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/auto_receptionists/{autoReceptionistId}/phone_numbers"
    path_params: [{name: autoReceptionistId, var: auto_receptionist_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    auto_receptionist_id: $auto_receptionist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign phone numbers
#
# POST /phone/auto_receptionists/{autoReceptionistId}/phone_numbers
# operationId: assignPhoneNumbersAutoReceptionist
export def "assign-phone-numbers-auto-receptionist" [
  auto_receptionist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-numbers: list # Provide either the unique identifier of the Phone Number in the `id` field or provide the phone number in the `number` field. — item shape: {id?: string, number?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/auto_receptionists/{autoReceptionistId}/phone_numbers"
    path_params: [{name: autoReceptionistId, var: auto_receptionist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    auto_receptionist_id: $auto_receptionist_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign a phone number
#
# DELETE /phone/auto_receptionists/{autoReceptionistId}/phone_numbers/{phoneNumberId}
# operationId: unassignAPhoneNumAutoReceptionist
export def "unassign-a-phone-num-auto-receptionist" [
  auto_receptionist_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/auto_receptionists/{autoReceptionistId}/phone_numbers/{phoneNumberId}"
    path_params: [{name: autoReceptionistId, var: auto_receptionist_id}, {name: phoneNumberId, var: phone_number_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    auto_receptionist_id: $auto_receptionist_id, phone_number_id: $phone_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List blocked lists
#
# GET /phone/blocked_list
# Returns: record<blocked_list: table<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string>, next_page_token: string, page_size: int, total_records: int>
# operationId: listBlockedList
export def "list-blocked-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The total number of records returned from a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/blocked_list"
    query: [{name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a blocked list
#
# POST /phone/blocked_list
# Returns: record<id: string>
# operationId: addAnumberToBlockedList
export def "add-anumber-to-blocked-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --block-type: string@block-type-completer # State whether you want the block type to be inbound or outbound. `inbound`: Pass this value to prevent the blocked number or prefix from calling in to phone users. `outbound`: Pass this value to prevent phone users from calling the blocked number or prefix.
  --comment: string # Provide a comment to help you identify the blocked number or prefix.
  --match-type: string@match-type-completer # Specify the match type for the blocked list. The values can be one of the following: `phoneNumber`: Choose this option (Phone Number Match) if you want to block a specific phone number. Then, in the `phone_number` field, provide the phone number along with the country code. `prefix`: Choose this option (Prefix Match) if you want to block all numbers with a specific country code and area code. Next, in the `phone_number` field, enter a country code as part of the prefix. For example, entering 1907 blocks numbers with country code 1 and area code 907.
  --phone-number: string # The phone number to be blocked if you passed "phoneNumber" as the value for the `match_type` field. If you passed "prefix" as the value for the `match_type` field, provide the prefix of the phone number here including the country code. For example, entering 1905 blocks numbers with country code 1 and area code 905.
  --status: string@status-completer-1 # Enable or disable the blocking. One of the following values are allowed: `active`: Keep the blocking active. `inactive`: Disable the blocking.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/blocked_list"
    body: {content_type: "application/json", kind: json, fields: [{name: block_type, var: block_type}, {name: comment, var: comment}, {name: match_type, var: match_type}, {name: phone_number, var: phone_number}, {name: status, var: status}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    block_type: $block_type, comment: $comment, match_type: $match_type, phone_number: $phone_number, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a blocked list
#
# DELETE /phone/blocked_list/{blockedListId}
# operationId: deleteABlockedList
export def "delete-a-blocked-list" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/blocked_list/{blockedListId}"
    path_params: [{name: blockedListId, var: blocked_list_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    blocked_list_id: $blocked_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get blocked list details
#
# GET /phone/blocked_list/{blockedListId}
# Returns: record<block_type: string, comment: string, id: string, match_type: string, phone_number: string, status: string>
# operationId: getABlockedList
export def "get-a-blocked-list" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/blocked_list/{blockedListId}"
    path_params: [{name: blockedListId, var: blocked_list_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    blocked_list_id: $blocked_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a blocked list
#
# PATCH /phone/blocked_list/{blockedListId}
# operationId: updateBlockedList
export def "update-blocked-list" [
  blocked_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --block-type: string@block-type-completer # State whether you want the block type to be inbound or outbound. `inbound`: Pass this value to prevent the blocked number or prefix from calling in to phone users. `outbound`: Pass this value to prevent phone users from calling the blocked number or prefix.
  --comment: string # Provide a comment to help you identify the blocked number or prefix.
  --match-type: string@match-type-completer # Specify the match type for the blocked list. The values can be one of the following: `phoneNumber`: Choose this option (Phone Number Match) if you want to block a specific phone number. Then, in the `phone_number` field, provide the phone number along with the country code. `prefix`: Choose this option (Prefix Match) if you want to block all numbers with a specific country code and area code. Next, in the `phone_number` field, enter a country code as part of the prefix. For example, entering 1907 blocks numbers with country code 1 and area code 907.
  --phone-number: string # The phone number to be blocked if you passed "phoneNumber" as the value for the `match_type` field. If you passed "prefix" as the value for the `match_type` field, provide the prefix of the phone number here including the country code. For example, entering 1905 blocks numbers with country code 1 and area code 905.
  --status: string@status-completer-1 # Enable or disable the blocking. One of the following values are allowed: `active`: Keep the blocking active. `inactive`: Disable the blocking.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/blocked_list/{blockedListId}"
    path_params: [{name: blockedListId, var: blocked_list_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: block_type, var: block_type}, {name: comment, var: comment}, {name: match_type, var: match_type}, {name: phone_number, var: phone_number}, {name: status, var: status}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    blocked_list_id: $blocked_list_id, block_type: $block_type, comment: $comment, match_type: $match_type, phone_number: $phone_number, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add BYOC phone numbers
#
# POST /phone/byoc_numbers
# Returns: record<phone_numbers: table<id: string, number: string>>
# operationId: addBYOCNumber
export def "add-byoc-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  carrier: string # Name of the carrier.
  phone_numbers: list<string> # Phone number(s) to be added to Zoom. The value should be in e164 format.
  --site-id: string # Unique identifier of the site. This field is only required if you have enabled multiple sites in the account. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) or [Adding a site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites#h_05c88e35-1593-491f-b1a8-b7139a75dc15) for details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/byoc_numbers"
    body: {content_type: "application/json", kind: json, fields: [{name: carrier, var: carrier}, {name: phone_numbers, var: phone_numbers}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [201, 300]
    auth: bearer
  } {
    carrier: $carrier, phone_numbers: $phone_numbers, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get account's call logs
#
# GET /phone/call_logs
# Returns: record<call_logs: table<answer_start_time: string, call_id: string, call_type: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, id: string, owner: record, path: string, rate: string, recording_id: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: string>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int>
# operationId: accountCallLogs
export def "account-call-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --from: string # Start date from which you would like to get the call logs. The start date should be within past six months. The API only returns data pertaining to a month. Thus, the date range(defined using "from" and "to" fields) for which the call logs are to be returned must not exceed a month.
  --to: string # The end date upto which you would like to get the call logs for. The end date should be within past six months.
  --type: string # The type of the call logs. The value can be either "all" or "missed".
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --path: string # Filter the API response by [path](https://support.zoom.us/hc/en-us/articles/360021114452-Viewing-and-identifying-logs#h_646b46c6-0623-4ab1-8b8b-ea5b8bcef679) of the call. The value of this field can be one of the following: `voiceMail`, `message`, `forward`, `extension`, `callQueue`, `ivrMenu`, `companyDirectory`, `autoReceptionist`, `contactCenter`, `disconnected`, `commonAreaPhone`, `pstn`, `transfer`, `sharedLines`, `sharedLineGroup`, `tollFreeBilling`, `meetingService`, `parkPickup`, `parkTimeout`, `monitor`, `takeover`, `sipGroup`
  --time-type: string@time-type-completer # Enables you to sort call logs by start or end time. Choose the sort time value. Values include `startTime` or `endTime`. (default: startTime)
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites). Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by call logs of a specific phone site.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/call_logs"
    query: [{name: page_size, var: page_size}, {name: from, var: from}, {name: to, var: to}, {name: type, var: type}, {name: next_page_token, var: next_page_token}, {name: path, var: path}, {name: time_type, var: time_type}, {name: site_id, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, from: $from, to: $to, type: $type, next_page_token: $next_page_token, path: $path, time_type: $time_type, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List call queues
#
# GET /phone/call_queues
# Returns: record<call_queues: table<extension_number: int, id: string, name: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int>
# operationId: listCallQueues
export def "list-call-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned from a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/call_queues"
    query: [{name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a call queue
#
# POST /phone/call_queues
# Returns: record<extension_number: int, id: string, name: string, status: string>
# operationId: createCallQueue
export def "create-call-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the Call Queue.
  --extension-number: int # Phone extension number for the site. If a site code has been [assigned](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number instead of the original extension number..
  --members: record # A list of one or more phone users to be included in the call queue. Provide either users or common area phone(s). Provide at least one user in the users object. — shape: {common_area_phone_ids?: list<string>, users?: list}
  name: string # Name of the Call Queue.
  site_id: string # Unique identifier of the site. Required only if [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) have been enabled. This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/call_queues"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: extension_number, var: extension_number}, {name: members, var: members}, {name: name, var: name}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    description: $description, extension_number: $extension_number, members: $members, name: $name, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a call queue
#
# DELETE /phone/call_queues/{callQueueId}
# operationId: deleteACallQueue
export def "delete-a-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/call_queues/{callQueueId}"
    path_params: [{name: callQueueId, var: call_queue_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get call queue details
#
# GET /phone/call_queues/{callQueueId}
# Returns: record<extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, name: string, phone_numbers: table<id: string, number: string, source: string>, site: record<id: string, name: string>, status: string>
# operationId: getACallQueue
export def "get-a-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/call_queues/{callQueueId}"
    path_params: [{name: callQueueId, var: call_queue_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    call_queue_id: $call_queue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update call queue details
#
# PATCH /phone/call_queues/{callQueueId}
# operationId: updateCallQueue
export def "update-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the Call Queue.
  --extension-number: int # Phone extension number for the site. If a site code has been [assigned](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number instead of the original extension number.
  --name: string # Name of the Call Queue.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) where the Call Queue is assigned.
  --status: string@status-completer-1 # Status of the Call Queue. Allowed values: `active` `inactive`
  --timezone: string # [Timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) of the Call Queue.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/call_queues/{callQueueId}"
    path_params: [{name: callQueueId, var: call_queue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: extension_number, var: extension_number}, {name: name, var: name}, {name: site_id, var: site_id}, {name: status, var: status}, {name: timezone, var: timezone}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, description: $description, extension_number: $extension_number, name: $name, site_id: $site_id, status: $status, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change call queue manager
#
# PUT /phone/call_queues/{callQueueId}/manager
# operationId: changeCallQueueManager
export def "change-call-queue-manager" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --member-id: string # Unique Identifier (userId) or email address of the user who will be the new call queue manager.
]: any -> any {
  $in | http-request {
    method: put
    path: "/phone/call_queues/{callQueueId}/manager"
    path_params: [{name: callQueueId, var: call_queue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: member_id, var: member_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign all members
#
# DELETE /phone/call_queues/{callQueueId}/members
# operationId: unassignAllMembers
export def "unassign-all-members" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/call_queues/{callQueueId}/members"
    path_params: [{name: callQueueId, var: call_queue_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add members to a call queue
#
# POST /phone/call_queues/{callQueueId}/members
# Returns: record
# operationId: addMembersToCallQueue
export def "add-members-to-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: record # A maximum of 10 members can be added at a time. — shape: {common_area_phone_ids?: list<string>, users?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/call_queues/{callQueueId}/members"
    path_params: [{name: callQueueId, var: call_queue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign a member
#
# DELETE /phone/call_queues/{callQueueId}/members/{memberId}
# operationId: unassignMemberFromCallQueue
export def "unassign-member-from-call-queue" [
  call_queue_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/call_queues/{callQueueId}/members/{memberId}"
    path_params: [{name: callQueueId, var: call_queue_id}, {name: memberId, var: member_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign all phone numbers
#
# DELETE /phone/call_queues/{callQueueId}/phone_numbers
# Returns: record
# operationId: unassignAPhoneNumCallQueue
export def "unassign-a-phone-num-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/call_queues/{callQueueId}/phone_numbers"
    path_params: [{name: callQueueId, var: call_queue_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign numbers to a call queue
#
# POST /phone/call_queues/{callQueueId}/phone_numbers
# Returns: record
# operationId: assignPhoneToCallQueue
export def "assign-phone-to-call-queue" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-numbers: list # Provide either the `id` or the `number` field. Only a max of 5 numbers can be assigned to a call queue at a time. — item shape: {id?: string, number?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/call_queues/{callQueueId}/phone_numbers"
    path_params: [{name: callQueueId, var: call_queue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign a phone number
#
# DELETE /phone/call_queues/{callQueueId}/phone_numbers/{phoneNumberId}
# Returns: record
# operationId: unAssignPhoneNumCallQueue
export def "un-assign-phone-num-call-queue" [
  call_queue_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/call_queues/{callQueueId}/phone_numbers/{phoneNumberId}"
    path_params: [{name: callQueueId, var: call_queue_id}, {name: phoneNumberId, var: phone_number_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, phone_number_id: $phone_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get call queue recordings
#
# GET /phone/call_queues/{callQueueId}/recordings
# Returns: record<from: string, next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string>, to: string, total_records: string>
# operationId: getCallQueueRecordings
export def "get-call-queue-recordings" [
  call_queue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --from: string # Start date (within a 6 month range). (format: date)
  --to: string # End date (within a 6 month range). (format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/call_queues/{callQueueId}/recordings"
    path_params: [{name: callQueueId, var: call_queue_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    call_queue_id: $call_queue_id, page_size: $page_size, next_page_token: $next_page_token, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List calling plans
#
# GET /phone/calling_plans
# Returns: record<calling_plans: table<assigned: int, available: int, name: string, subscribed: int, type: int>>
# operationId: listCallingPlans
export def "list-calling-plans" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/calling_plans"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List common area phones
#
# GET /phone/common_area_phones
# Returns: record<common_area_phones: table<calling_plans: list, device_type: string, display_name: string, id: string, mac_address: string, phone_numbers: list, site: record, status: string>, next_page_token: string, page_size: int, total_records: int>
# operationId: listCommonAreaPhones
export def "list-common-area-phones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The total number of records returned from a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/common_area_phones"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a common area phone
#
# POST /phone/common_area_phones
# Returns: record<display_name: string, id: string>
# operationId: addCommonAreaPhone
export def "add-common-area-phone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description for the common area phone.
  display_name: string # Display name of the Common area phone.
  extension_number: int # Extension number assigned to the common area phone. If site code is enabled, provide the short extension number instead.
  mac_address: string # Mac Address (serial number) of the common area desk phone. These examples show the formats supported: `64-16-7f-37-90-92` or `64167f379092`
  --model: string # Device Model name. Refer to the "Model Name" field in [this](https://marketplace.zoom.us/docs/api-reference/other-references/zoomphone-supporteddevice) table.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672). This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
  --time-zone: string # [Timezone ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists) for the common area phone.
  type: string # Phone device manufacturer name. Refer to the "Manufacturer Name" field in [this](https://marketplace.zoom.us/docs/api-reference/other-references/zoomphone-supporteddevice) table.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/common_area_phones"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: extension_number, var: extension_number}, {name: mac_address, var: mac_address}, {name: model, var: model}, {name: site_id, var: site_id}, {name: time_zone, var: time_zone}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    description: $description, display_name: $display_name, extension_number: $extension_number, mac_address: $mac_address, model: $model, site_id: $site_id, time_zone: $time_zone, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a common area phone
#
# DELETE /phone/common_area_phones/{commonAreaPhoneId}
# operationId: deleteCommonAreaPhone
export def "delete-common-area-phone" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/common_area_phones/{commonAreaPhoneId}"
    path_params: [{name: commonAreaPhoneId, var: common_area_phone_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    common_area_phone_id: $common_area_phone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get common area phone details
#
# GET /phone/common_area_phones/{commonAreaPhoneId}
# Returns: record<device_type: string, id: string, mac_address: string, name: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string>
# operationId: getACommonAreaPhone
export def "get-a-common-area-phone" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/common_area_phones/{commonAreaPhoneId}"
    path_params: [{name: commonAreaPhoneId, var: common_area_phone_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    common_area_phone_id: $common_area_phone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update common area phone
#
# PATCH /phone/common_area_phones/{commonAreaPhoneId}
# operationId: updateCommonAreaPhone
export def "update-common-area-phone" [
  common_area_phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-name: string # Display name of the common area phone.
  --extension-number: int # Extension number of the phone. If site code is enabled, provide short extension number instead.
  --mac-address: string # Mac address or serial number of the device. Examples of supported format: "64-16-7f-37-90-92" or "64167f379092".
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites) to which the common area desk phone is assigned.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/common_area_phones/{commonAreaPhoneId}"
    path_params: [{name: commonAreaPhoneId, var: common_area_phone_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: extension_number, var: extension_number}, {name: mac_address, var: mac_address}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    common_area_phone_id: $common_area_phone_id, display_name: $display_name, extension_number: $extension_number, mac_address: $mac_address, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change main company number
#
# PUT /phone/company_number
# operationId: changeMainCompanyNumber
export def "change-main-company-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --phone-number: string # Provide either the unique identifier of the phone number (id) or the phone number itself in e164 format (e.g: +199955500123).
]: any -> any {
  $in | http-request {
    method: put
    path: "/phone/company_number"
    body: {content_type: "application/json", kind: json, fields: [{name: phone_number, var: phone_number}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    phone_number: $phone_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List devices
#
# GET /phone/devices
# Returns: record<devices: table<assignee: record, device_type: string, display_name: string, id: string, mac_address: string, site: record, status: string>, next_page_token: string, page_size: int, total_records: string>
# operationId: listPhoneDevices
export def "list-phone-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-5 # State of the device. The value should be either `assigned` to list devices that have been assigned to user(s) or `unassigned` to list devices that have not yet been assigned to any user in the Zoom account. (required)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/devices"
    query: [{name: type, var: type, required: true}, {name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    type: $type, next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a device
#
# POST /phone/devices
# operationId: addPhoneDevice
export def "add-phone-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --assigned-to: string # User ID or email address of the user to whom this device is to be assigned. The User ID and the email of the user can be retrieved using the [List Users](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/users) API.
  display_name: string # Display name of the desk phone.
  mac_address: string # The MAC address of the desk phone. Note: If you're using a wireless phone, enter the wired MAC address, not the wireless MAC address.
  --model: string # Model name of the device.
  --type: string # Manufacturer (brand) name of the device.
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/devices"
    body: {content_type: "application/json", kind: json, fields: [{name: assigned_to, var: assigned_to}, {name: display_name, var: display_name}, {name: mac_address, var: mac_address}, {name: model, var: model}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    assigned_to: $assigned_to, display_name: $display_name, mac_address: $mac_address, model: $model, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a device
#
# DELETE /phone/devices/{deviceId}
# operationId: deleteADevice
export def "delete-a-device" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  http-request {
    method: delete
    path: "/phone/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get device details
#
# GET /phone/devices/{deviceId}
# Returns: record<assignee: record<extension_number: int, id: string, name: string>, device_type: string, display_name: string, id: string, mac_address: string, provision: record<sip_accounts: list<record>, type: string, url: string>, site: record<id: string, name: string>, status: string>
# operationId: getADevice
export def "get-a-device" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a device
#
# PATCH /phone/devices/{deviceId}
# operationId: updateADevice
export def "update-a-device" [
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
  --accept: string@accept-completer # Response content type
  --assigned-to: string # User ID or email address of the user to whom this device is to be assigned. The User ID and the email of the user can be retrieved using the [List Users](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/users) API.
  --display-name: string # Display name of the desk phone.
  --mac-address: string # The MAC address of the desk phone. Note: If you're using a wireless phone, enter the wired MAC address, not the wireless MAC address.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/devices/{deviceId}"
    path_params: [{name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assigned_to, var: assigned_to}, {name: display_name, var: display_name}, {name: mac_address, var: mac_address}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id, assigned_to: $assigned_to, display_name: $display_name, mac_address: $mac_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List call logs
#
# GET /phone/metrics/call_logs
# Returns: record<call_logs: table<call_id: string, callee: record, caller: record, date_time: string, direction: string, duration: int, mos: string>, from: string, next_page_token: string, page_size: int, to: string, total_records: int>
# operationId: listCallLogsMetrics
export def "list-call-logs-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date for the report in `yyyy-mm-dd` format. Specify a 30 day range using the `from` and `to` parameters as the response provides a maximum of a month worth of data per API request.
  --to: string # End date for the report in `yyyy-mm-dd` format.
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites). Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by call logs of a specific phone site.
  --quality-type: string # Filter call logs by voice quality. Zoom uses MOS of 3.5 as a general baseline to categorize calls by call quality. A MOS greater than or equal to 3.5 means good quality, while below 3.5 means poor quality. The value of this field can be one of the following: * `good`: Retrieve call logs of the call(s) with good quality of voice. * `bad`: Retrieve call logs of the call(s) with good quality of voice. * `all`: Retrieve all call logs without filtering by voice quality.
  --page-size: int # The number of records returned within a single call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/metrics/call_logs"
    query: [{name: from, var: from}, {name: to, var: to}, {name: site_id, var: site_id}, {name: quality_type, var: quality_type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, site_id: $site_id, quality_type: $quality_type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get call QoS
#
# GET /phone/metrics/call_logs/{callId}/qos
# Returns: record<call_id: string, callee_qos: record<receiving: list<record>, sending: list<record>>, caller_qos: record<receiving: list<record>, sending: list<record>>>
# operationId: getCallQoS
export def "get-call-qo-s" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/metrics/call_logs/{callId}/qos"
    path_params: [{name: callId, var: call_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    call_id: $call_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get call details from call log
#
# GET /phone/metrics/call_logs/{call_id}
# Returns: record<call_id: string, callee: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, caller: record<codec: string, device_type: string, extension_number: string, headset: string, isp: string, microphone: string, phone_number: string, site_id: string>, date_time: string, direction: string, duration: int, mos: string>
# operationId: getCallLogMetricsDetails
export def "get-call-log-metrics-details" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/metrics/call_logs/{call_id}"
    path_params: [{name: call_id, var: call_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    call_id: $call_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List phone numbers
#
# GET /phone/numbers
# Returns: record<next_page_token: string, page_size: int, phone_numbers: table<assignee: record, capability: list, carrier: record, display_name: string, id: string, location: string, number: string, number_type: string, sip_group: record, site: record, source: string, status: string>, total_records: int>
# operationId: listAccountPhoneNumbers
export def "list-account-phone-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --type: string@type-completer-6 # Query response by number assignment. The value can be one of the following: `assigned`: The number has been assigned to either a user, a call queue, an auto-receptionist or a common area phone in an account. `unassigned`: The number is not assigned to anyone. `all`: Include both assigned and unassigned numbers in the response. `byoc`: Include Bring Your Own Carrier (BYOC) numbers only in the response.
  --extension-type: string@extension-type-completer # The type of assignee to whom the number is assigned. The value can be one of the following: `user` `callQueue` `autoReceptionist` `commonAreaPhone`
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --number-type: string@number-type-completer # The type of phone number. The value can be either `toll` or `tollfree`.
  --pending-numbers: oneof<nothing, bool> # Include or exclude pending numbers in the response. The value can be either `true` or `false`.
  --site-id: string # Unique identifier of the site. Use this query parameter if you have enabled multiple sites and would like to filter the response of this API call by a specific phone site. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) or [Adding a site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites#h_05c88e35-1593-491f-b1a8-b7139a75dc15) for details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/numbers"
    query: [{name: next_page_token, var: next_page_token}, {name: type, var: type}, {name: extension_type, var: extension_type}, {name: page_size, var: page_size}, {name: number_type, var: number_type}, {name: pending_numbers, var: pending_numbers}, {name: site_id, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    next_page_token: $next_page_token, type: $type, extension_type: $extension_type, page_size: $page_size, number_type: $number_type, pending_numbers: $pending_numbers, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get phone number details
#
# GET /phone/numbers/{numberId}
# Returns: record<assignee: record<extension_number: int, id: string, name: string, type: string>, capability: list<string>, display_name: string, id: string, location: string, number: string, number_type: string, site: record<id: string, name: string>, source: string, status: string>
# operationId: getPhoneNumberDetails
export def "get-phone-number-details" [
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/numbers/{numberId}"
    path_params: [{name: numberId, var: number_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    number_id: $number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update phone number details
#
# PATCH /phone/numbers/{numberId}
# operationId: updatePhoneNumberDetails
export def "update-phone-number-details" [
  number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --capability: list<string> # Phone number capability. Values: `outgoing` or `incoming`. Add one or both.
  --display-name: string # Phone number display name.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/numbers/{numberId}"
    path_params: [{name: numberId, var: number_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: capability, var: capability}, {name: display_name, var: display_name}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    number_id: $number_id, capability: $capability, display_name: $display_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get call recordings
#
# GET /phone/recordings
# Returns: record<next_page_token: string, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: int, id: string, owner: record, recording_type: string, site: record>, total_records: int>
# operationId: getPhoneRecordings
export def "get-phone-recordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. The default is **30**, and the maximum is **100**.
  --next-page-token: string # The current page number of returned records.
  --from: string # Start date and time in **yyyy-mm-dd** format or **yyyy-MM-dd’T’HH:mm:ss’Z’** format. The date range defined by the from and to parameters should only be one month as the report includes only one month worth of data at once.
  --to: string # End date and time in **yyyy-mm-dd** format or **yyyy-MM-dd’T’HH:mm:ss’Z’** format, the same formats supported by the `from` parameter.
  --owner-type: string # The owner type. The allowed values are null, `user`, or `callQueue`. The default is null. If null, returns all owner types. (default: all)
  --recording-type: string # The recording type. The allowed values are null, `OnDemand`, or `Automatic`. The default is null. If null, returns all recording types.
  --site-id: string # The site ID. The default is `All sites`. (default: All sites)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/recordings"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to}, {name: owner_type, var: owner_type}, {name: recording_type, var: recording_type}, {name: site_id, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token, from: $from, to: $to, owner_type: $owner_type, recording_type: $recording_type, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get operation logs report
#
# GET /phone/reports/operationlogs
# Returns: record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>>
# operationId: getPSOperationLogs
export def "get-ps-operation-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report provides only one month worth of data per API request.
  --to: string # End date in 'yyyy-mm-dd' format.
  --category-type: string # Filter the response by the category of the action performed. By default, the value of this field is "all" and thus, the response will include log of all operations for the defined period.To only include response for a specific category type, provide a value for `category_type` from this [table](http://marketplace.zoom.us/docs/phone-operation-categories ). (default: all)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/reports/operationlogs"
    query: [{name: from, var: from}, {name: to, var: to}, {name: category_type, var: category_type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, category_type: $category_type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List setting templates
#
# GET /phone/setting_templates
# Returns: record<next_page_token: string, page_size: int, templates: table<description: string, id: string, name: string, type: string>, total_records: int>
# operationId: listSettingTemplates
export def "list-setting-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # Number of records returns within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --site-id: string # Unique identifier of the site. This field is required only if multiple sites have been enabled. of the site. Required only when multiple sites are enabled. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) for details. If this is not provided, the response lists the account level setting templates.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/setting_templates"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: site_id, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a setting template
#
# POST /phone/setting_templates
# Returns: record<description: string, id: string, name: string, type: string>
# operationId: addSettingTemplate
export def "add-setting-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # A description of the template.
  name: string # The name of the template.
  --site-id: string # Unique identifier of the site. Required only when multiple sites are enabled. See [Managing multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) for details.
  type: string@type-completer-7 # The type of template. Values include `user`, `group`, `autoReceptionist`, `commonarea`, or `interop`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/setting_templates"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: site_id, var: site_id}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    description: $description, name: $name, site_id: $site_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get setting template details
#
# GET /phone/setting_templates/{templateId}
# Returns: record<description: string, id: string, name: string, policy: record<ad_hoc_call_recording: record<enable: bool, recording_start_prompt: bool, recording_transcription: bool>, auto_call_recording: record<enable: bool, recording_calls: string, recording_start_prompt: bool, recording_transcription: bool>, sms: record<enable: bool, international_sms: bool>, voicemail: record<allow_transcription: bool, enable: bool>>, profile: record<area_code: string, country: string>, type: string, user_settings: record<audio_prompt_language: string, block_calls_without_caller_id: bool, call_handling: record<business_hours: record, close_hours: record>, desk_phone: record<pin_code: string>, hold_music: string>>
# operationId: getSettingTemplate
export def "get-setting-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom-query-fields: string # Provide the name of the field to use to filter the response. For example, if you provide "description" as the value of the field, you will get a response similar to the following: {“description”: “template description”}.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/setting_templates/{templateId}"
    path_params: [{name: templateId, var: template_id}]
    query: [{name: custom_query_fields, var: custom_query_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, custom_query_fields: $custom_query_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a setting template
#
# PATCH /phone/setting_templates/{templateId}
# operationId: updateSettingTemplate
export def "update-setting-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # The description of the template.
  --name: string # Specify the name of the template.
  --policy: record # shape: {ad_hoc_call_recording?: record, auto_call_recording?: record, sms?: record, voicemail?: record}
  --profile: record # shape: {area_code?: string, country?: string}
  --user-settings: record # shape: {audio_prompt_language?: string, block_calls_without_caller_id?: bool, call_handling?: record, desk_phone?: record, hold_music?: "default"|"disable"}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/setting_templates/{templateId}"
    path_params: [{name: templateId, var: template_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: policy, var: policy}, {name: profile, var: profile}, {name: user_settings, var: user_settings}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    template_id: $template_id, description: $description, name: $name, policy: $policy, profile: $profile, user_settings: $user_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List shared line groups
#
# GET /phone/shared_line_groups
# Returns: record<next_page_token: string, page_size: int, shared_line_groups: table<display_name: string, extension_number: int, id: string, phone_numbers: list, site: record, status: string>, total_records: int>
# operationId: listSharedLineGroups
export def "list-shared-line-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/shared_line_groups"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a shared line group
#
# POST /phone/shared_line_groups
# operationId: createASharedLineGroup
export def "create-a-shared-line-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Provide a description for the shared line group.
  display_name: string # Provide a name to help identify the shared line group.
  --extension-number: int # Extension number to be assigned to the shared line group. If a [site code has been assigned](https://support.zoom.us/hc/en-us/articles/360020809672#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b) to the site, provide the short extension number
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) that you would like to use for the shared line group. You will only be able to add members that belong to this site to the shared line group. This field is required only if the [multiple sites](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-multiple-sites) option has been enabled for the account.
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/shared_line_groups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: display_name, var: display_name}, {name: extension_number, var: extension_number}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    description: $description, display_name: $display_name, extension_number: $extension_number, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}
# operationId: deleteASharedLineGroup
export def "delete-a-shared-line-group" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/shared_line_groups/{sharedLineGroupId}"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a shared line group
#
# GET /phone/shared_line_groups/{sharedLineGroupId}
# Returns: record<display_name: string, extension_number: int, id: string, members: record<common_area_phones: list<record>, users: list<record>>, phone_numbers: table<id: string, number: string>, primary_number: string, site: record<id: string, name: string>, status: string, timezone: string>
# operationId: getASharedLineGroup
export def "get-a-shared-line-group" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/shared_line_groups/{sharedLineGroupId}"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a shared line group
#
# PATCH /phone/shared_line_groups/{sharedLineGroupId}
# operationId: updateASharedLineGroup
export def "update-a-shared-line-group" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --display-name: string # Display Name of the Shared Line Group.
  --extension-number: int # Extension number assigned to the Shared Line Group.
  --primary-number: record # If you have multiple direct phone numbers assigned to the shared line group, select a number from those numbers as the primary number. The primary number shares the same line as the extension number. This means if a caller is routed to the shared line group through an auto receptionist, the line associated with the primary number will be used. A pending number cannot be used as a Primary Number. — shape: {id?: string, number?: string}
  --status: string@status-completer-1 # Status of the Shared Line Group.
  --timezone: string # Timezone to be used for the Business Hours. A value should be provided from the IDs listed [here](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones).
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/shared_line_groups/{sharedLineGroupId}"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_name, var: display_name}, {name: extension_number, var: extension_number}, {name: primary_number, var: primary_number}, {name: status, var: status}, {name: timezone, var: timezone}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id, display_name: $display_name, extension_number: $extension_number, primary_number: $primary_number, status: $status, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign members of a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/members
# operationId: deleteMembersOfSLG
export def "delete-members-of-slg" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/shared_line_groups/{sharedLineGroupId}/members"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add members to a shared line group
#
# POST /phone/shared_line_groups/{sharedLineGroupId}/members
# operationId: addMembersToSharedLineGroup
export def "add-members-to-shared-line-group" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: record # Members can comprise of users on the account as well as common area phones. You can add a maximum of 10 members at once. — shape: {common_area_phone_ids?: list<string>, users?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/shared_line_groups/{sharedLineGroupId}/members"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign a member from a shared line group
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/members/{memberId}
# operationId: deleteAMemberSLG
export def "delete-a-member-slg" [
  shared_line_group_id: string
  member_id: string
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
    path: "/phone/shared_line_groups/{sharedLineGroupId}/members/{memberId}"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign phone numbers
#
# POST /phone/shared_line_groups/{sharedLineGroupId}/phone_numbers
# operationId: assignPhoneNumbersSLG
export def "assign-phone-numbers-slg" [
  shared_line_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-numbers: list # Phone number(s) to be assigned to the Shared Line Group. — item shape: {id?: string, number?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/shared_line_groups/{sharedLineGroupId}/phone_numbers"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign a phone number
#
# DELETE /phone/shared_line_groups/{sharedLineGroupId}/phone_numbers/{phoneNumberId}
# operationId: deleteAPhoneNumberSLG
export def "delete-a-phone-number-slg" [
  shared_line_group_id: string
  phone_number_id: string
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
    path: "/phone/shared_line_groups/{sharedLineGroupId}/phone_numbers/{phoneNumberId}"
    path_params: [{name: sharedLineGroupId, var: shared_line_group_id}, {name: phoneNumberId, var: phone_number_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    shared_line_group_id: $shared_line_group_id, phone_number_id: $phone_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List BYOC SIP trunks
#
# GET /phone/sip_trunk/trunks
# Returns: record<byoc_sip_trunk: table<carrier: string, carrier_account: string, id: string, name: string, region: string, sbc_label: string>, next_page_token: string, page_size: int>
# operationId: listBYOCSIPTrunk
export def "list-byocsip-trunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/sip_trunk/trunks"
    query: [{name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List phone sites
#
# GET /phone/sites
# Returns: record<next_page_token: string, page_size: string, sites: table<country: record, id: string, main_auto_receptionist: record, name: string, site_code: string>, total_records: string>
# operationId: listPhoneSites
export def "list-phone-sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/sites"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a phone site
#
# POST /phone/sites
# Returns: record<id: string, name: string>
# operationId: createPhoneSite
export def "create-phone-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  auto_receptionist_name: string # Display name of the [auto-receptionist](https://support.zoom.us/hc/en-us/articles/360021121312-Managing-Auto-Receptionists-and-Integrated-Voice-Response-IVR-) for the site.
  --default-emergency-address: record # shape: {address_line1: string, address_line2?: string, city: string, country: string, state_code: string, zip: string}
  name: string # Name of the Site.
  --short-extension: record # Short extension of the phone site. — shape: {length?: int}
  --site-code: int # Identifier for a site. If site code is enabled, this field is required.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/sites"
    body: {content_type: "application/json", kind: json, fields: [{name: auto_receptionist_name, var: auto_receptionist_name}, {name: default_emergency_address, var: default_emergency_address}, {name: name, var: name}, {name: short_extension, var: short_extension}, {name: site_code, var: site_code}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    auto_receptionist_name: $auto_receptionist_name, default_emergency_address: $default_emergency_address, name: $name, short_extension: $short_extension, site_code: $site_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a phone site
#
# DELETE /phone/sites/{siteId}
# operationId: deletePhoneSite
export def "delete-phone-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --transfer-site-id: string # The Site ID of another site where the assets of the current site (users, numbers and phones) can be transferred to. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/phone/sites/{siteId}"
    path_params: [{name: siteId, var: site_id}]
    query: [{name: transfer_site_id, var: transfer_site_id, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, transfer_site_id: $transfer_site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get phone site details
#
# GET /phone/sites/{siteId}
# Returns: record<country: record<code: string, name: string>, id: string, main_auto_receptionist: record<extension_id: string, extension_number: int, id: string, name: string>, name: string, short_extension: record<length: int>, site_code: int>
# operationId: getASite
export def "get-a-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/phone/sites/{siteId}"
    path_params: [{name: siteId, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update phone site details
#
# PATCH /phone/sites/{siteId}
# operationId: updateSiteDetails
export def "update-site-details" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the site.
  --site-code: int # [Site Code](https://support.zoom.us/hc/en-us/articles/360020809672-Managing-Multiple-Sites#h_79ca9c8f-c97b-4486-aa59-d0d9d31a525b).
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/sites/{siteId}"
    path_params: [{name: siteId, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: site_code, var: site_code}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id, name: $name, site_code: $site_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List phone users
#
# GET /phone/users
# Returns: record<next_page_token: string, page_size: int, total_records: int, users: table<calling_plans: list, email: string, extension_number: int, id: string, name: string, phone_user_id: string, site: record, status: string>>
# operationId: listPhoneUsers
export def "list-phone-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned from a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --site-id: string # Unique Identifier of the site. This can be retrieved from the [List Phone Sites](https://marketplace.zoom.us/docs/api-reference/zoom-api/phone-site/listphonesites) API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/users"
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: site_id, var: site_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, next_page_token: $next_page_token, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's profile
#
# GET /phone/users/{userId}
# Returns: record<calling_plan: table<type: int>, email: string, extension_number: int, id: string, phone_numbers: table<id: string, number: string>, phone_user_id: string, site_admin: bool, site_id: string, status: string>
# operationId: phoneUser
export def "phone-user" [
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
    path: "/phone/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user's profile
#
# PATCH /phone/users/{userId}
# operationId: updateUserProfile
export def "update-user-profile" [
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
  --extension-number: string # The extension number of the user. The number must be complete (i.e. site number + short extension).
  --site-id: string # Unique identifier of the [site](https://support.zoom.us/hc/en-us/articles/360020809672) where the user should be moved or assigned.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: extension_number, var: extension_number}, {name: site_id, var: site_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204, 300]
    auth: bearer
  } {
    user_id: $user_id, extension_number: $extension_number, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's call logs
#
# GET /phone/users/{userId}/call_logs
# Returns: record<call_logs: table<accepted_by: record, call_id: string, callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, charge: string, client_code: string, date_time: string, direction: string, duration: int, forwarded_by: record, forwarded_to: record, has_recording: bool, has_voicemail: bool, id: string, outgoing_by: record, path: string, rate: string, recording_type: string, result: string, site: record, user_id: string, waiting_time: int>, from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int>
# operationId: phoneUserCallLogs
export def "phone-user-call-logs" [
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
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --type: string@type-completer-8
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --phone-number: string # Filter API responses to include call logs of only the phone number defined in this field.
  --time-type: string@time-type-completer # Enables you to sort call logs by start or end time. Choose the sort time value. Values include `startTime` or `endTime`. (default: startTime)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/users/{userId}/call_logs"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: type, var: type}, {name: next_page_token, var: next_page_token}, {name: phone_number, var: phone_number}, {name: time_type, var: time_type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, from: $from, to: $to, type: $type, next_page_token: $next_page_token, phone_number: $phone_number, time_type: $time_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user's call log
#
# DELETE /phone/users/{userId}/call_logs/{callLogId}
# operationId: deleteCallLog
export def "delete-call-log" [
  user_id: string
  call_log_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/users/{userId}/call_logs/{callLogId}"
    path_params: [{name: userId, var: user_id}, {name: callLogId, var: call_log_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, call_log_id: $call_log_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign calling plan to a user
#
# POST /phone/users/{userId}/calling_plans
# operationId: assignCallingPlan
export def "assign-calling-plan" [
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
  --calling-plans: list # item shape: {type?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/phone/users/{userId}/calling_plans"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: calling_plans, var: calling_plans}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id, calling_plans: $calling_plans
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign user's calling plan
#
# DELETE /phone/users/{userId}/calling_plans/{type}
# operationId: unassignCallingPlan
export def "unassign-calling-plan" [
  user_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/users/{userId}/calling_plans/{type}"
    path_params: [{name: userId, var: user_id}, {name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [204, 300]
    auth: bearer
  } {
    user_id: $user_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign phone number to user
#
# POST /phone/users/{userId}/phone_numbers
# Returns: record<phone_numbers: table<id: string, number: string>>
# operationId: assignPhoneNumber
export def "assign-phone-number" [
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
  --phone-numbers: list # item shape: {id?: string, number?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/users/{userId}/phone_numbers"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: phone_numbers, var: phone_numbers}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id, phone_numbers: $phone_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign phone number
#
# DELETE /phone/users/{userId}/phone_numbers/{phoneNumberId}
# operationId: UnassignPhoneNumber
export def "unassign-phone-number" [
  user_id: string
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/users/{userId}/phone_numbers/{phoneNumberId}"
    path_params: [{name: userId, var: user_id}, {name: phoneNumberId, var: phone_number_id}]
    accept: ["application/json", "application/xml"]
    ok: [204, 300]
    auth: bearer
  } {
    user_id: $user_id, phone_number_id: $phone_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's recordings
#
# GET /phone/users/{userId}/recordings
# Returns: record<from: string, next_page_token: string, page_count: int, page_size: int, recordings: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, direction: string, download_url: string, duration: string, id: string>, to: string, total_records: int>
# operationId: phoneUserRecordings
export def "phone-user-recordings" [
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
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --from: string # Start date for the query in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the response includes only one month worth of recording data. The month defined should fall within the last six months. (format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/users/{userId}/recordings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, next_page_token: $next_page_token, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's settings
#
# GET /phone/users/{userId}/settings
# Returns: record<area_code: string, company_number: string, desk_phone: record<keys_positions: record<primary_number: string>>, outbound_caller: record<number: string>, outbound_caller_ids: record<is_default: bool, name: string, number: string>, voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>>
# operationId: phoneUserSettings
export def "phone-user-settings" [
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
    path: "/phone/users/{userId}/settings"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove shared access
#
# DELETE /phone/users/{userId}/settings/{settingType}
# operationId: deleteUserSetting
export def "delete-user-setting" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --shared-id: string # Required only for voicemail setting type. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/phone/users/{userId}/settings/{settingType}"
    path_params: [{name: userId, var: user_id}, {name: settingType, var: setting_type}]
    query: [{name: shared_id, var: shared_id, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, setting_type: $setting_type, shared_id: $shared_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update shared access
#
# PATCH /phone/users/{userId}/settings/{settingType}
# operationId: updateUserSetting
export def "update-user-setting" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voice-mail: record # Update the voicemail setting. — shape: {access_user_id?: string, delete?: bool, download?: bool, shared_id?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/phone/users/{userId}/settings/{settingType}"
    path_params: [{name: userId, var: user_id}, {name: settingType, var: setting_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: voice_mail, var: voice_mail}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, setting_type: $setting_type, voice_mail: $voice_mail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set up shared access
#
# POST /phone/users/{userId}/settings/{settingType}
# Returns: record<voice_mail: record<access_user_id: string, delete: bool, download: bool, shared_id: string>>
# operationId: addUserSetting
export def "add-user-setting" [
  user_id: string
  setting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --voice-mail: record # Update the voicemail setting. — shape: {access_user_id?: string, delete?: bool, download?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/phone/users/{userId}/settings/{settingType}"
    path_params: [{name: userId, var: user_id}, {name: settingType, var: setting_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: voice_mail, var: voice_mail}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, setting_type: $setting_type, voice_mail: $voice_mail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's voicemails
#
# GET /phone/users/{userId}/voice_mails
# Returns: record<from: string, next_page_token: string, page_count: int, page_size: int, to: string, total_records: int, voice_mails: table<callee_name: string, callee_number: string, callee_number_type: string, caller_name: string, caller_number: string, caller_number_type: string, date_time: string, download_url: string, duration: string, id: string, status: string>>
# operationId: phoneUserVoiceMails
export def "phone-user-voice-mails" [
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
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --status: string@status-completer-2 # Status of the voice mail (default: all)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --from: string # Start date for the query in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the response includes only one month worth of voicemail data. The month defined should fall within the last six months. (format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/phone/users/{userId}/voice_mails"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: status, var: status}, {name: next_page_token, var: next_page_token}, {name: from, var: from}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, status: $status, next_page_token: $next_page_token, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a voicemail
#
# DELETE /phone/voice_mails/{voicemailId}
# operationId: deleteVoicemail
export def "delete-voicemail" [
  voicemail_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    method: delete
    path: "/phone/voice_mails/{voicemailId}"
    path_params: [{name: voicemailId, var: voicemail_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    voicemail_id: $voicemail_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get sign In / sign out activity report
#
# GET /report/activities
# Returns: record<activity_logs: table<client_type: string, email: string, ip_address: string, time: string, type: string, version: string>, from: string, next_page_token: string, page_size: string, to: string>
# operationId: reportSignInSignOutActivities
export def "report-sign-in-sign-out-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date for which you would like to view the activity logs report. Using the `from` and `to` parameters, specify a monthly date range for the report as the API only provides one month worth of data in one request. The specified date range should fall within the last six months. (format: date)
  --to: string # End date up to which you would like to view the activity logs report. (format: date)
  --page-size: int # The number of records to be returned within a single API call
  --next-page-token: string # Next page token is used to paginate through large result sets
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/activities"
    query: [{name: from, var: from}, {name: to, var: to}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get cloud recording usage report
#
# GET /report/cloud_recording
# Returns: record<from: string, to: string, cloud_recording_storage: table<date: string, free_usage: string, plan_usage: string, usage: string>>
# operationId: reportCloudRecording
export def "report-cloud-recording" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/cloud_recording"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get daily usage report
#
# GET /report/daily
# Returns: record<dates: table<date: string, meeting_minutes: int, meetings: int, new_users: int, participants: int>, month: int, year: int>
# operationId: reportDaily
export def "report-daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --year: int # Year for this report
  --month: int # Month for this report
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/daily"
    query: [{name: year, var: year}, {name: month, var: month}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    year: $year, month: $month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting detail reports
#
# GET /report/meetings/{meetingId}
# Returns: record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string>
# operationId: reportMeetingDetails
export def "report-meeting-details" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/report/meetings/{meetingId}"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting participant reports
#
# GET /report/meetings/{meetingId}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, registrant_id: string, user_email: string, user_id: string>>
# operationId: reportMeetingParticipants
export def "report-meeting-participants" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Provide `registrant_id` as the value for this field if you would like to see the registrant ID attribute in the response of this API call. A registrant ID is a unique identifier of a [meeting registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/meetingregistrants).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/meetings/{meetingId}/participants"
    path_params: [{name: meetingId, var: meeting_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_fields, var: include_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    meeting_id: $meeting_id, page_size: $page_size, next_page_token: $next_page_token, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting poll reports
#
# GET /report/meetings/{meetingId}/polls
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: reportMeetingPolls
export def "report-meeting-polls" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/report/meetings/{meetingId}/polls"
    path_params: [{name: meetingId, var: meeting_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    meeting_id: $meeting_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get operation logs report
#
# GET /report/operationlogs
# Returns: record<next_page_token: string, page_size: int, operation_logs: table<action: string, category_type: string, operation_detail: string, operator: string, time: string>>
# operationId: reportOperationLogs
export def "report-operation-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --category-type: string@category-type-completer # **Optional** Filter your response by a category type to see reports for a specific category. The value for this field can be one of the following: `all``user``user_settings``account``billing``im``recording``phone_contacts``webinar``sub_account``role``zoom_rooms`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/operationlogs"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: category_type, var: category_type}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token, category_type: $category_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get telephone reports
#
# GET /report/telephone
# Returns: record<from: string, next_page_token: int, page_count: int, page_size: int, to: string, total_records: int, telephony_usage: table<call_in_number: string, country_name: string, dept: string, duration: int, end_time: string, host_email: string, host_id: string, host_name: string, meeting_id: int, meeting_type: string, phone_number: string, rate: float, signaled_number: string, start_time: string, total: float, type: string, uuid: string>>
# operationId: reportTelephone
export def "report-telephone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-9 # Audio types:`1` - Toll-free Call-in & Call-out.`2` - Toll `3` - SIP Connected Audio (default: 1)
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/telephone"
    query: [{name: type, var: type}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    type: $type, from: $from, to: $to, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get active/inactive host reports
#
# GET /report/users
# Returns: record<from: string, next_page_token: string, page_count: int, page_number: int, page_size: int, to: string, total_records: int, total_meeting_minutes: int, total_meetings: int, total_participants: int, users: table<custom_attributes: record, dept: string, email: string, id: string, meeting_minutes: int, meetings: int, participants: int, type: int, user_name: string>>
# operationId: reportUsers
export def "report-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-10 # Active or inactive hosts.`active` - Active hosts. `inactive` - Inactive hosts.
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/users"
    query: [{name: type, var: type}, {name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    type: $type, from: $from, to: $to, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get meeting reports
#
# GET /report/users/{userId}/meetings
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, from: string, meetings: table<custom_keys: list, duration: int, end_time: string, id: int, participants_count: int, source: string, start_time: string, topic: string, total_minutes: int, type: int, user_email: string, user_name: string, uuid: string>, to: string>
# operationId: reportMeetings
export def "report-meetings" [
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
  --from: string # Start date in 'yyyy-mm-dd' format. The date range defined by the "from" and "to" parameters should only be one month as the report includes only one month worth of data at once. (required, format: date)
  --to: string # End date. (required, format: date)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --type: string@type-completer-11 # The meeting types: `past` - Past meetings.`pastOne` - Past one user meetings. (default: past)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/users/{userId}/meetings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: type, var: type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, from: $from, to: $to, page_size: $page_size, next_page_token: $next_page_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar detail reports
#
# GET /report/webinars/{webinarId}
# Returns: record<custom_keys: table<key: string, value: string>, dept: string, duration: int, end_time: string, id: int, participants_count: int, start_time: string, topic: string, total_minutes: int, tracking_fields: table<field: string, value: string>, type: int, user_email: string, user_name: string, uuid: string>
# operationId: reportWebinarDetails
export def "report-webinar-details" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/report/webinars/{webinarId}"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar participant reports
#
# GET /report/webinars/{webinarId}/participants
# Returns: record<next_page_token: string, page_count: int, page_size: int, total_records: int, participants: table<customer_key: string, duration: int, failover: bool, id: string, join_time: string, leave_time: string, name: string, user_email: string, user_id: string>>
# operationId: reportWebinarParticipants
export def "report-webinar-participants" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --include-fields: string@include-fields-completer-1 # Enter 'registrant_id' as the value for this field if you would like to see the registrant ID attribute included in the response of this API call. A registrant ID is a unique identifier of a [webinar registrant](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarregistrants).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/report/webinars/{webinarId}/participants"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: include_fields, var: include_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, page_size: $page_size, next_page_token: $next_page_token, include_fields: $include_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar poll reports
#
# GET /report/webinars/{webinarId}/polls
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: reportWebinarPolls
export def "report-webinar-polls" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/report/webinars/{webinarId}/polls"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get webinar Q&A report
#
# GET /report/webinars/{webinarId}/qa
# Returns: record<id: int, questions: table<email: string, name: string, question_details: list>, start_time: string, uuid: string>
# operationId: reportWebinarQA
export def "report-webinar-qa" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/report/webinars/{webinarId}/qa"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List roles
#
# GET /roles
# Returns: record<roles: table<description: string, id: string, name: string, total_members: int>, total_records: int>
# operationId: roles
export def "roles" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/roles"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a role
#
# POST /roles
# operationId: createRole
export def "create-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description of the role.
  --name: string # Name of the role.
  --privileges: list<string> # Privileges assigned to the role. Can be one or a combination of [these permissions](https://marketplace.zoom.us/docs/api-reference/other-references/privileges).
]: any -> any {
  $in | http-request {
    method: post
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: privileges, var: privileges}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201, 300]
    auth: bearer
  } {
    description: $description, name: $name, privileges: $privileges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a role
#
# DELETE /roles/{roleId}
# Returns: record
# operationId: deleteRole
export def "delete-role" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/roles/{roleId}"
    path_params: [{name: roleId, var: role_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get role information
#
# GET /roles/{roleId}
# Returns: record<description: string, id: string, name: string, privileges: list<string>, sub_account_privileges: record<second_level: int>, total_members: int>
# operationId: getRoleInformation
export def "get-role-information" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/roles/{roleId}"
    path_params: [{name: roleId, var: role_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    role_id: $role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update role information
#
# PATCH /roles/{roleId}
# operationId: updateRole
export def "update-role" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # Description of the role.
  --id: string # Role Id.
  --name: string # Name of the role.
  --privileges: list<string> # Privileges assigned to the role. Can be one or a combination of [these permissions](https://marketplace.zoom.us/docs/api-reference/other-references/privileges).
  --sub-account-privileges: record # This field will only be displayed to accounts that are enrolled in the partner plan and follow master accounts and sub accounts structure. — shape: {second_level?: int}
  --total-members: int # Total members assigned to that role.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/roles/{roleId}"
    path_params: [{name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}, {name: privileges, var: privileges}, {name: sub_account_privileges, var: sub_account_privileges}, {name: total_members, var: total_members}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    role_id: $role_id, description: $description, id: $id, name: $name, privileges: $privileges, sub_account_privileges: $sub_account_privileges, total_members: $total_members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List members in a role
#
# GET /roles/{roleId}/members
# Returns: record<members: table<department: string, email: string, first_name: string, id: string, last_name: string, type: int>, next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int>
# operationId: roleMembers
export def "role-members" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-count: string # The number of pages returned for this request.
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-size: int # The number of records returned within a single API call. (default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles/{roleId}/members"
    path_params: [{name: roleId, var: role_id}]
    query: [{name: page_count, var: page_count}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}, {name: page_size, var: page_size}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, page_count: $page_count, page_number: $page_number, next_page_token: $next_page_token, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign a role
#
# POST /roles/{roleId}/members
# Returns: record<add_at: string, ids: string>
# operationId: AddRoleMembers
export def "add-role-members" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --members: list # Array of userId/user email of users to whom you would like to assign this role. Upto 30 users can be assigned a role at once. — item shape: {email?: string, id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles/{roleId}/members"
    path_params: [{name: roleId, var: role_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: members, var: members}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    role_id: $role_id, members: $members
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unassign a role
#
# DELETE /roles/{roleId}/members/{memberId}
# operationId: roleMemberDelete
export def "role-member-delete" [
  role_id: string
  member_id: string
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
    path: "/roles/{roleId}/members/{memberId}"
    path_params: [{name: roleId, var: role_id}, {name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    role_id: $role_id, member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Zoom Rooms
#
# GET /rooms
# Returns: record<next_page_token: string, page_size: int, rooms: table<activation_code: string, id: string, location_id: string, name: string, room_id: string, status: string>>
# operationId: listZoomRooms
export def "list-zoom-rooms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-3 # The status of the Zoom Room.
  --type: string@type-completer-12 # Type of the Zoom Rooms.
  --unassigned-rooms: oneof<nothing, bool> # Use this query parameter with a value of `true` if you would like to see Zoom Rooms in your account that have not been assigned to anyone yet. (default: false)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --location-id: string # Parent location ID of the Zoom Room.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms"
    query: [{name: status, var: status}, {name: type, var: type}, {name: unassigned_rooms, var: unassigned_rooms}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: location_id, var: location_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    status: $status, type: $type, unassigned_rooms: $unassigned_rooms, page_size: $page_size, next_page_token: $next_page_token, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Zoom Room
#
# POST /rooms
# Returns: record<id: string, location_id: string, name: string, room_id: string, type: string>
# operationId: addARoom
export def "add-a-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --location-id: string # **Optional**Location ID of the lowest level location in the [location hierarchy](https://support.zoom.us/hc/en-us/articles/115000342983-Zoom-Rooms-Location-Hierarchy) where the Zoom Room is to be added. For instance if the structure of the location hierarchy is set up as “country, states, city, campus, building, floor”, a room can only be added under the floor level location. This ID can be retrieved from the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
  name: string # Name of the Zoom Room.
  type: string@type-completer-12 # Type of the Zoom Room.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rooms"
    body: {content_type: "application/json", kind: json, fields: [{name: location_id, var: location_id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    location_id: $location_id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room account profile
#
# GET /rooms/account_profile
# Returns: record<basic: record<required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>>
# operationId: getZRAccountProfile
export def "get-zr-account-profile" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/account_profile"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Zoom Room account profile
#
# PATCH /rooms/account_profile
# Returns: record
# operationId: updateZRAccProfile
export def "update-zr-acc-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rooms/account_profile"
    body: {content_type: "application/json", kind: json, fields: [{name: basic, var: basic}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    basic: $basic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room account settings
#
# GET /rooms/account_settings
# Returns: record
# operationId: getZRAccountSettings
export def "get-zr-account-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string@setting-type-completer # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: View digital signage settings of the Zoom Rooms Account. (required, default: meeting)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/account_settings"
    query: [{name: setting_type, var: setting_type, required: true, default: meeting}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    setting_type: $setting_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Zoom Room account settings
#
# PATCH /rooms/account_settings
# Returns: record
# operationId: updateZoomRoomAccSettings
export def "update-zoom-room-acc-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: View digital signage settings of the Zoom Rooms Account. (required, default: meeting)
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, email_address_prompt_before_recording?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, make_room_alternative_host?: bool, secure_connection_channel?: bool, ... (10 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_stable_detected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rooms/account_settings"
    query: [{name: setting_type, var: setting_type, required: true, default: meeting}]
    body: {content_type: "application/json", kind: json, fields: [{name: zoom_rooms, var: zoom_rooms}, {name: client_alert, var: client_alert}, {name: digital_signage, var: digital_signage}, {name: notification, var: notification}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    setting_type: $setting_type, zoom_rooms: $zoom_rooms, client_alert: $client_alert, digital_signage: $digital_signage, notification: $notification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List digital signage contents
#
# GET /rooms/digital_signage
# Returns: record<contents: table<id: string, name: string>, next_page_token: string, page_size: int>
# operationId: listDigitalSignageContent
export def "list-digital-signage-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # Specify the type of digital signane resource. The value can be one of the following: * `content`: Returns information about content files. * `folder`: Returns information about the folder where the content files are located.
  --folder-id: string # Unique identifier of the folder where the content is located. Provide this field if you would like to filter the response by contents that are only available in a specific folder.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/digital_signage"
    query: [{name: type, var: type}, {name: folder_id, var: folder_id}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    type: $type, folder_id: $folder_id, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update E911 digital signage
#
# PATCH /rooms/events
# Returns: record<event_id: string>
# operationId: manageE911signage
export def "manage-e911signage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --method: string@method-completer # To display the emergency content on the Zoom Rooms digital signage display, set the value of this field to be `zoomroom.emergency_alert_displayed`.
  --params: record # shape: {content?: string, target_ids?: list<string>, target_type?: "account"|"location"|"room"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rooms/events"
    body: {content_type: "application/json", kind: json, fields: [{name: method, var: method}, {name: params, var: params}]}
    accept: ["application/json", "application/xml"]
    ok: [202]
    auth: bearer
  } {
    method: $method, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Zoom Room locations
#
# GET /rooms/locations
# Returns: record<locations: table<id: string, name: string, parent_location_id: string, type: string>, next_page_token: string, page_size: int>
# operationId: listZRLocations
export def "list-zr-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --parent-location-id: string # A unique identifier of the parent location. For instance, if a Zoom Room is located in Floor 1 of Building A, the location of Building A will be the parent location of Floor 1. Use this parameter to filter the response by a specific location hierarchy level.
  --type: string # Use this field to filter the response by the type of location. The value can be one of the following: `country`, `states`, `city`, `campus`, `building`, `floor`.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/locations"
    query: [{name: parent_location_id, var: parent_location_id}, {name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    parent_location_id: $parent_location_id, type: $type, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a location
#
# POST /rooms/locations
# Returns: record<id: string, name: string, parent_location_id: string, type: string>
# operationId: addAZRLocation
export def "add-azr-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Name of the location. The name must be unique and shouldn't have already been used in the same account.
  --parent-location-id: string # The location ID of the location that is a level higher from the location that is being added. For example, to add a City named "City 1" as the child location under a State named "State 1", you must provide the location ID of "State 1". This can be retrieved using the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rooms/locations"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent_location_id, var: parent_location_id}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    name: $name, parent_location_id: $parent_location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room location structure
#
# GET /rooms/locations/structure
# Returns: record<structures: list<string>>
# operationId: getZRLocationStructure
export def "get-zr-location-structure" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/locations/structure"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Zoom Rooms location structure
#
# PATCH /rooms/locations/structure
# operationId: updateZoomRoomsLocationStructure
export def "update-zoom-rooms-location-structure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --structures: list<string> # Location Structure. The value can be either one or a combination of the following strings separated by comma: `country`, `state`, `city`, `campus`, `building`, `floor`
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rooms/locations/structure"
    body: {content_type: "application/json", kind: json, fields: [{name: structures, var: structures}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    structures: $structures
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room location profile
#
# GET /rooms/locations/{locationId}
# Returns: record<basic: record<address: string, "description ": string, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string, timezone: string>>
# operationId: getZRLocationProfile
export def "get-zr-location-profile" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/locations/{locationId}"
    path_params: [{name: locationId, var: location_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Zoom Room location profile
#
# PATCH /rooms/locations/{locationId}
# operationId: updateZRLocationProfile
export def "update-zr-location-profile" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {address?: string, description ?: string, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string, timezone?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rooms/locations/{locationId}"
    path_params: [{name: locationId, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: basic, var: basic}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, basic: $basic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change the assigned parent location
#
# PUT /rooms/locations/{locationId}/location
# operationId: changeParentLocation
export def "change-parent-location" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --parent-location-id: string # Location ID of the new Parent Location under which you the child location will be positioned. This can be retrieved from the [List Zoom Room Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> any {
  $in | http-request {
    method: put
    path: "/rooms/locations/{locationId}/location"
    path_params: [{name: locationId, var: location_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: parent_location_id, var: parent_location_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    location_id: $location_id, parent_location_id: $parent_location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get location settings
#
# GET /rooms/locations/{locationId}/settings
# Returns: record
# operationId: getZRLocationSettings
export def "get-zr-location-settings" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: Digital signage settings of the Zoom Rooms Account. (required, default: meeting)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/locations/{locationId}/settings"
    path_params: [{name: locationId, var: location_id}]
    query: [{name: setting_type, var: setting_type, required: true, default: meeting}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    location_id: $location_id, setting_type: $setting_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update location settings
#
# PATCH /rooms/locations/{locationId}/settings
# operationId: updateZRLocationSettings
export def "update-zr-location-settings" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. `signage`: Digital signage settings. (required, default: meeting)
  --meeting-security: record # shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_accept_incoming_call_and_fecc?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_self_view?: bool, lock_speaker_volume_control?: bool, ... (13 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rooms/locations/{locationId}/settings"
    path_params: [{name: locationId, var: location_id}]
    query: [{name: setting_type, var: setting_type, required: true, default: meeting}]
    body: {content_type: "application/json", kind: json, fields: [{name: meeting_security, var: meeting_security}, {name: zoom_rooms, var: zoom_rooms}, {name: client_alert, var: client_alert}, {name: digital_signage, var: digital_signage}, {name: notification, var: notification}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    location_id: $location_id, setting_type: $setting_type, meeting_security: $meeting_security, zoom_rooms: $zoom_rooms, client_alert: $client_alert, digital_signage: $digital_signage, notification: $notification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check-in or check-out of a Zoom Room
#
# PATCH /rooms/{id}/events
# operationId: checkInRooms
export def "check-in-rooms" [
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
  --method: string # The value of this field can be one of the following: * zoomroom.check_in * zoomroom.check_out
  --params: record # shape: {calendar_id?: string, change_key?: string, event_id: string, resource_email?: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rooms/{id}/events"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: method, var: method}, {name: params, var: params}]}
    accept: ["application/json", "application/xml"]
    ok: [202]
    auth: bearer
  } {
    id: $id, method: $method, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Zoom Room
#
# DELETE /rooms/{roomId}
# Returns: record
# operationId: deleteAZoomRoom
export def "delete-a-zoom-room" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/{roomId}"
    path_params: [{name: roomId, var: room_id}]
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room profile
#
# GET /rooms/{roomId}
# Returns: record<basic: record<activation_code: string, hide_room_in_contacts: bool, name: string, required_code_to_ext: bool, room_passcode: string, support_email: string, support_phone: string>>
# operationId: getZRProfile
export def "get-zr-profile" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/{roomId}"
    path_params: [{name: roomId, var: room_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a Zoom Room profile
#
# PATCH /rooms/{roomId}
# Returns: record
# operationId: updateRoomProfile
export def "update-room-profile" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --basic: record # shape: {hide_room_in_contacts?: bool, name?: string, required_code_to_ext?: bool, room_passcode?: string, support_email?: string, support_phone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rooms/{roomId}"
    path_params: [{name: roomId, var: room_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: basic, var: basic}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, basic: $basic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Zoom Room devices
#
# GET /rooms/{roomId}/devices
# Returns: record<devices: table<app_version: string, device_system: string, device_type: string, id: string, room_name: string, status: string>>
# operationId: listZRDevices
export def "list-zr-devices" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/rooms/{roomId}/devices"
    path_params: [{name: roomId, var: room_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change Zoom Rooms' app version
#
# PUT /rooms/{roomId}/devices/{deviceId}/app_version
# operationId: changeZoomRoomsAppVersion
export def "change-zoom-rooms-app-version" [
  room_id: string
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
  --accept: string@accept-completer # Response content type
  --action: string@action-completer-8 # Specify one of the following values for this field: `upgrade`: Upgrade to the latest Zoom Rooms App Version. `downgrade`: Downgrade the Zoom Rooms App Version. `cancel`: Cancel an ongoing upgrade or downgrade process.
]: any -> any {
  $in | http-request {
    method: put
    path: "/rooms/{roomId}/devices/{deviceId}/app_version"
    path_params: [{name: roomId, var: room_id}, {name: deviceId, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, device_id: $device_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Change a Zoom Room's location
#
# PUT /rooms/{roomId}/location
# operationId: changeZRLocation
export def "change-zr-location" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --location-id: string # Location ID of the location where Zoom Room is to be assigned. This can be retrieved from the `id` property in the response of [List Zoom Rooms Locations](https://marketplace.zoom.us/docs/api-reference/zoom-api/rooms-location/listzrlocations) API.
]: any -> any {
  $in | http-request {
    method: put
    path: "/rooms/{roomId}/location"
    path_params: [{name: roomId, var: room_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: location_id, var: location_id}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, location_id: $location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Zoom Room settings
#
# GET /rooms/{roomId}/settings
# Returns: record
# operationId: getZRSettings
export def "get-zr-settings" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to retrieve. `alert`: Alert Settings applied on the Zoom Rooms Account. `meeting`: Meeting settings of the Zoom Rooms Account. (required, default: meeting)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rooms/{roomId}/settings"
    path_params: [{name: roomId, var: room_id}]
    query: [{name: setting_type, var: setting_type, required: true, default: meeting}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, setting_type: $setting_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update Zoom Room settings
#
# PATCH /rooms/{roomId}/settings
# operationId: updateZRSettings
export def "update-zr-settings" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setting-type: string # The type of setting that you would like to update. `alert`: Alert Settings applied on the Zoom Room. `meeting`: Meeting settings of the Zoom Room. `signage`: Digital signage settings applied on the Zoom Room.
  --meeting-security: record # shape: {encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool}
  --zoom-rooms: record # shape: {allow_multiple_content_sharing?: bool, audio_device_daily_auto_test?: bool, auto_direct_sharing?: bool, auto_start_scheduled_meeting?: bool, auto_stop_scheduled_meeting?: bool, count_attendees_number_in_room?: bool, display_feedback_survey?: bool, display_meeting_list?: bool, display_top_banner?: bool, encrypt_shared_screen_content?: bool, hide_id_for_private_meeting?: bool, hide_share_instruction?: bool, send_whiteboard_to_internal_contact_only?: bool, show_alert_before_meeting?: bool, ... (9 more fields)}
  --client-alert: record # The Client Alert Settings section includes alerts that display on the TV screen of the Zoom Room. Disable these settings if you have deliberately disconnected one or more peripheral devices or have never enabled them. — shape: {detect_bluetooth_microphone_error_alert?: bool, detect_bluetooth_speaker_error_alert?: bool, detect_camera_error_alert?: bool, detect_microphone_error_alert?: bool, detect_speaker_error_alert?: bool}
  --digital-signage: record # shape: {banner?: record, display_period?: record, enable_digital_signage?: bool, layout?: string, mute?: bool, play_list?: list}
  --notification: record # [Notifications Settings](https://support.zoom.us/hc/en-us/articles/205394099-Zoom-Room-Alerts#h_b430b5f2-5150-4522-9c96-c77f22ab70bc) includes the circumstances in which the room sends an email alert to the support team to notify them of a potentially urgent issue. These issues can affect the operation of the room, but do not display on the TV screen. The email alert is sent to the email address specified in the Notification Email Recipients section. — shape: {audio_meet_usability_threshold?: bool, audio_not_meet_usability_threshold?: bool, battery_is_charging?: bool, battery_low_and_not_charging?: bool, battery_percentage?: string, controller_scheduling_disconnected?: bool, controller_scheduling_reconnected?: bool, cpu_usage_high_detected?: bool, mic_speaker_camera_disconnected?: bool, mic_speaker_camera_reconnected?: bool, network_unstable_detected?: bool, sip_registration_failed?: bool, sip_registration_re_enabled?: bool, ... (3 more fields)}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/rooms/{roomId}/settings"
    path_params: [{name: roomId, var: room_id}]
    query: [{name: setting_type, var: setting_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: meeting_security, var: meeting_security}, {name: zoom_rooms, var: zoom_rooms}, {name: client_alert, var: client_alert}, {name: digital_signage, var: digital_signage}, {name: notification, var: notification}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, setting_type: $setting_type, meeting_security: $meeting_security, zoom_rooms: $zoom_rooms, client_alert: $client_alert, digital_signage: $digital_signage, notification: $notification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List SIP phones
#
# GET /sip_phones
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, phones: table<authorization_name: string, domain: string, id: string, password: string, proxy_server: string, proxy_server2: string, proxy_server3: string, register_server: string, register_server2: string, register_server3: string, registration_expire_time: int, transport_protocol: string, transport_protocol2: string, transport_protocol3: string, user_email: string, user_name: string, voice_mail: string>, total_records: int>
# operationId: listSipPhones
export def "list-sip-phones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --search-key: string # User name or email address of a user. If this parameter is provided, only the SIP phone system integration enabled for that specific user will be returned. Otherwise, all SIP phones on an account will be returned.
  --page-size: int # The number of records returned within a single API call.
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sip_phones"
    query: [{name: page_number, var: page_number}, {name: search_key, var: search_key}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number, search_key: $search_key, page_size: $page_size, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Enable SIP phone
#
# POST /sip_phones
# operationId: createSIPPhone
export def "create-sip-phone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authorization_name: string # Authorization name of the user registered for SIP Phone.
  domain: string # The name or IP address of your provider’s SIP domain. (example: CDC.WEB).
  password: string # The password generated for the user in the SIP account.
  proxy_server: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  --proxy-server2: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server, or empty.
  --proxy-server3: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server, or empty.
  register_server: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --register-server2: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --register-server3: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --registration-expire-time: int # The number of minutes after which the SIP registration of the Zoom client user will expire, and the client will auto register to the SIP server. (default: 60)
  --transport-protocol: string@transport-protocol-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol2: string@transport-protocol2-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol3: string@transport-protocol3-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  user_email: string # The email address of the user to associate with the SIP Phone. Can add [.win, .mac, .android, .ipad, .iphone, .linux, .pc, .mobile, .pad] at the end of the email (ex. user@test.com.mac) to add accounts for different platforms for the same user. (format: email)
  user_name: string # The phone number associated with the user in the SIP account.
  voice_mail: string # The number to dial for checking voicemail.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sip_phones"
    body: {content_type: "application/json", kind: json, fields: [{name: authorization_name, var: authorization_name}, {name: domain, var: domain}, {name: password, var: password}, {name: proxy_server, var: proxy_server}, {name: proxy_server2, var: proxy_server2}, {name: proxy_server3, var: proxy_server3}, {name: register_server, var: register_server}, {name: register_server2, var: register_server2}, {name: register_server3, var: register_server3}, {name: registration_expire_time, var: registration_expire_time}, {name: transport_protocol, var: transport_protocol}, {name: transport_protocol2, var: transport_protocol2}, {name: transport_protocol3, var: transport_protocol3}, {name: user_email, var: user_email}, {name: user_name, var: user_name}, {name: voice_mail, var: voice_mail}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization_name: $authorization_name, domain: $domain, password: $password, proxy_server: $proxy_server, proxy_server2: $proxy_server2, proxy_server3: $proxy_server3, register_server: $register_server, register_server2: $register_server2, register_server3: $register_server3, registration_expire_time: $registration_expire_time, transport_protocol: $transport_protocol, transport_protocol2: $transport_protocol2, transport_protocol3: $transport_protocol3, user_email: $user_email, user_name: $user_name, voice_mail: $voice_mail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SIP phone
#
# DELETE /sip_phones/{phoneId}
# Returns: record
# operationId: deleteSIPPhone
export def "delete-sip-phone" [
  phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sip_phones/{phoneId}"
    path_params: [{name: phoneId, var: phone_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    phone_id: $phone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update SIP phone
#
# PATCH /sip_phones/{phoneId}
# Returns: record
# operationId: updateSIPPhone
export def "update-sip-phone" [
  phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  authorization_name: string # Authorization name of the user registered for SIP Phone.
  domain: string # The name or IP address of your provider’s SIP domain. (example: CDC.WEB).
  password: string # The password generated for the user in the SIP account.
  proxy_server: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  proxy_server2: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  proxy_server3: string # IP address of the proxy server for SIP requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address. If you are not using a proxy server, this value can be the same as the Register Server.
  register_server: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  register_server2: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  register_server3: string # IP address of the server that accepts REGISTER requests. Note that if you are using the UDP transport protocol, the default port is 5060. If you are using UDP with a different port number, that port number must be included with the IP address.
  --registration-expire-time: int # The number of minutes after which the SIP registration of the Zoom client user will expire, and the client will auto register to the SIP server. (default: 60)
  --transport-protocol: string@transport-protocol-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol2: string@transport-protocol2-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  --transport-protocol3: string@transport-protocol3-completer # Protocols supported by the SIP provider. The value must be either `UDP`, `TCP`, `TLS`, `AUTO`.
  user_name: string # The phone number associated with the user in the SIP account.
  voice_mail: string # The number to dial for checking voicemail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sip_phones/{phoneId}"
    path_params: [{name: phoneId, var: phone_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorization_name, var: authorization_name}, {name: domain, var: domain}, {name: password, var: password}, {name: proxy_server, var: proxy_server}, {name: proxy_server2, var: proxy_server2}, {name: proxy_server3, var: proxy_server3}, {name: register_server, var: register_server}, {name: register_server2, var: register_server2}, {name: register_server3, var: register_server3}, {name: registration_expire_time, var: registration_expire_time}, {name: transport_protocol, var: transport_protocol}, {name: transport_protocol2, var: transport_protocol2}, {name: transport_protocol3, var: transport_protocol3}, {name: user_name, var: user_name}, {name: voice_mail, var: voice_mail}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    phone_id: $phone_id, authorization_name: $authorization_name, domain: $domain, password: $password, proxy_server: $proxy_server, proxy_server2: $proxy_server2, proxy_server3: $proxy_server3, register_server: $register_server, register_server2: $register_server2, register_server3: $register_server3, registration_expire_time: $registration_expire_time, transport_protocol: $transport_protocol, transport_protocol2: $transport_protocol2, transport_protocol3: $transport_protocol3, user_name: $user_name, voice_mail: $voice_mail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List SIP trunk numbers
#
# GET /sip_trunk/numbers
# Returns: record<phone_numbers: table<country: string, number: string>, total_records: int>
# operationId: listSipTrunkNumbers
export def "list-sip-trunk-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/sip_trunk/numbers"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List tracking fields
#
# GET /tracking_fields
# Returns: record<total_records: int, tracking_fields: table<id: string, field: string, recommended_values: list, required: bool, visible: bool>>
# operationId: trackingfieldList
export def "trackingfield-list" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/tracking_fields"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a tracking field
#
# POST /tracking_fields
# Returns: record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool>
# operationId: trackingfieldCreate
export def "trackingfield-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --field: string # Label/ Name for the tracking field.
  --recommended-values: list<string> # Array of recommended values
  --required: oneof<nothing, bool> # Tracking Field Required
  --visible: oneof<nothing, bool> # Tracking Field Visible
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tracking_fields"
    body: {content_type: "application/json", kind: json, fields: [{name: field, var: field}, {name: recommended_values, var: recommended_values}, {name: required, var: required}, {name: visible, var: visible}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    field: $field, recommended_values: $recommended_values, required: $required, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a tracking field
#
# DELETE /tracking_fields/{fieldId}
# operationId: trackingfieldDelete
export def "trackingfield-delete" [
  field_id: string
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
    path: "/tracking_fields/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    field_id: $field_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tracking field
#
# GET /tracking_fields/{fieldId}
# Returns: record<id: string, field: string, recommended_values: list<string>, required: bool, visible: bool>
# operationId: trackingfieldGet
export def "trackingfield-get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/tracking_fields/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    field_id: $field_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a tracking field
#
# PATCH /tracking_fields/{fieldId}
# operationId: trackingfieldUpdate
export def "trackingfield-update" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field: string # Label/ Name for the tracking field.
  --recommended-values: list<string> # Array of recommended values
  --required: oneof<nothing, bool> # Tracking Field Required
  --visible: oneof<nothing, bool> # Tracking Field Visible
]: any -> any {
  $in | http-request {
    method: patch
    path: "/tracking_fields/{fieldId}"
    path_params: [{name: fieldId, var: field_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: field, var: field}, {name: recommended_values, var: recommended_values}, {name: required, var: required}, {name: visible, var: visible}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    field_id: $field_id, field: $field, recommended_values: $recommended_values, required: $required, visible: $visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account's TSP information
#
# GET /tsp
# Returns: record<dial_in_number_unrestricted: bool, dial_in_numbers: table<code: string, number: string, type: string>, enable: bool, master_account_setting_extended: bool, modify_credential_forbidden: bool, tsp_bridge: string, tsp_enabled: bool, tsp_provider: string>
# operationId: tsp
export def "tsp" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/tsp"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update account's TSP information
#
# PATCH /tsp
# operationId: tspUpdate
export def "tsp-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dial-in-number-unrestricted: oneof<nothing, bool> # Control restriction on account users adding a TSP number outside of account's dial in numbers.
  --enable: oneof<nothing, bool> # Enable 3rd party audio conferencing for account users
  --master-account-setting-extended: oneof<nothing, bool> # For master account, extend its TSP setting to all sub accounts. For sub account, extend TSP setting from master account.
  --modify-credential-forbidden: oneof<nothing, bool> # Control restriction on account users being able to modify their TSP credentials.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
  --tsp-enabled: oneof<nothing, bool> # Enable TSP feature for account. This has to be enabled to use any other tsp settings/features.
  --tsp-provider: string # 3rd party audio conferencing provider
]: any -> any {
  $in | http-request {
    method: patch
    path: "/tsp"
    body: {content_type: "application/json", kind: json, fields: [{name: dial_in_number_unrestricted, var: dial_in_number_unrestricted}, {name: enable, var: enable}, {name: master_account_setting_extended, var: master_account_setting_extended}, {name: modify_credential_forbidden, var: modify_credential_forbidden}, {name: tsp_bridge, var: tsp_bridge}, {name: tsp_enabled, var: tsp_enabled}, {name: tsp_provider, var: tsp_provider}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    dial_in_number_unrestricted: $dial_in_number_unrestricted, enable: $enable, master_account_setting_extended: $master_account_setting_extended, modify_credential_forbidden: $modify_credential_forbidden, tsp_bridge: $tsp_bridge, tsp_enabled: $tsp_enabled, tsp_provider: $tsp_provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /users
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, users: table<created_at: string, custom_attributes: list, dept: string, email: string, first_name: string, group_ids: list, host_key: string, id: string, im_group_ids: list, last_client_version: string, last_login_time: string, last_name: string, plan_united_type: string, pmi: int, role_id: string, status: string, timezone: string, type: int, verified: int>>
# operationId: users
export def "users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-4 # User statuses:`active` - Users with an active status.`inactive` - Users who are deactivated.`pending` - Users with a pending status. (default: active)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --role-id: string # Unique identifier of the role. Provide this parameter if you would like to filter the response by a specific role. You can retrieve Role IDs from [List Roles](https://marketplace.zoom.us/docs/api-reference/zoom-api/roles/roles) API.
  --page-number: string # The page number of the current page in the returned records.
  --include-fields: string # Provide a value for this field if you would like to see the following attribute in the response of this API call: `custom_attributes`: Returns custom attributes that are associated with the user.`host_key`: Returns [host key](https://support.zoom.us/hc/en-us/articles/205172555-Using-your-host-key) of the user.
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: status, var: status}, {name: page_size, var: page_size}, {name: role_id, var: role_id}, {name: page_number, var: page_number}, {name: include_fields, var: include_fields}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    status: $status, page_size: $page_size, role_id: $role_id, page_number: $page_number, include_fields: $include_fields, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create users
#
# POST /users
# Returns: record<email: string, first_name: string, id: string, last_name: string, type: int>
# operationId: userCreate
export def "user-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  action: string@action-completer-9 # Specify how to create the new user: `create` - User will get an email sent from Zoom. There is a confirmation link in this email. The user will then need to use the link to activate their Zoom account. The user can then set or change their password.`autoCreate` - This action is provided for the enterprise customer who has a managed domain. This feature is disabled by default because of the security risk involved in creating a user who does not belong to your domain.`custCreate` - Users created via this option do not have passwords and will not have the ability to log into the Zoom Web Portal or the Zoom Client. These users can still host and join meetings using the `start_url` and `join_url` respectively. To use this option, you must contact the ISV Platform Sales team at isv@zoom.us.`ssoCreate` - This action is provided for the enabled “Pre-provisioning SSO User” option. A user created in this way has no password. If not a basic user, a personal vanity URL using the user name (no domain) of the provisioning email will be generated. If the user name or PMI is invalid or occupied, it will use a random number or random personal vanity URL.
  --user-info: record # shape: {email: string, first_name?: string, last_name?: string, password?: string, type: "1"|"2"|"3"|"99"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: user_info, var: user_info}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    action: $action, user_info: $user_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check a user email
#
# GET /users/email
# Returns: record<existed_email: bool>
# operationId: userEmail
export def "user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address to be verified. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/email"
    query: [{name: email, var: email, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get user's ZAK
#
# GET /users/me/zak
# Returns: record<token: string>
# operationId: userZak
export def "user-zak" [
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/me/zak"
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check a user's PM room
#
# GET /users/vanity_name
# Returns: record<existed: bool>
# operationId: userVanityName
export def "user-vanity-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --vanity-name: string # Personal meeting room name. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/vanity_name"
    query: [{name: vanity_name, var: vanity_name, required: true}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    vanity_name: $vanity_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user
#
# DELETE /users/{userId}
# operationId: userDelete
export def "user-delete" [
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
  --action: string@action-completer-10 # Delete action options:`disassociate` - Disassociate a user.`delete`- Permanently delete a user.Note: To delete pending user in the account, use `disassociate` (default: disassociate)
  --transfer-email: string # Transfer email.
  --transfer-meeting: oneof<nothing, bool> # Transfer meeting.
  --transfer-webinar: oneof<nothing, bool> # Transfer webinar.
  --transfer-recording: oneof<nothing, bool> # Transfer recording.
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: action, var: action}, {name: transfer_email, var: transfer_email}, {name: transfer_meeting, var: transfer_meeting}, {name: transfer_webinar, var: transfer_webinar}, {name: transfer_recording, var: transfer_recording}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, action: $action, transfer_email: $transfer_email, transfer_meeting: $transfer_meeting, transfer_webinar: $transfer_webinar, transfer_recording: $transfer_recording
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{userId}
# Returns: record<id: string, created_at: string, dept: string, email: string, first_name: string, last_client_version: string, last_login_time: string, last_name: string, pmi: int, role_name: string, timezone: string, type: int, use_pmi: bool, account_id: string, cms_user_id: string, company: string, custom_attributes: record<key: string, name: string, value: string>, group_ids: list<string>, host_key: string, im_group_ids: list<string>, jid: string, job_title: string, language: string, location: string, login_type: int, manager: string, personal_meeting_url: string, phone_country: string, phone_number: string, phone_numbers: record<code: string, country: string, number: string, verified: bool>, pic_url: string, plan_united_type: string, role_id: string, status: string, vanity_url: string, verified: int>
# operationId: user
export def "user" [
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
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: login_type, var: login_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, login_type: $login_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user
#
# PATCH /users/{userId}
# operationId: userUpdate
export def "user-update" [
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
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
  --cms-user-id: string # Kaltura user ID.
  --company: string # User's company.
  --custom-attributes: record # Custom attribute(s) of the user. — shape: {key?: string, name?: string, value?: string}
  --dept: string # Department for user profile: use for report.
  --first-name: string # User's first name. Cannot contain more than 5 Chinese characters.
  --group-id: string # Provide unique identifier of the group that you would like to add a [pending user](https://support.zoom.us/hc/en-us/articles/201363183-Managing-users#h_13c87a2a-ecd6-40ad-be61-a9935e660edb) to. The value of this field can be retrieved from [List Groups](https://marketplace.zoom.us/docs/api-reference/zoom-api/groups/groups) API.
  --host-key: string # Host key. It should be a 6-10 digit number.
  --job-title: string # User's job title.
  --language: string # language
  --last-name: string # User's last name. Cannot contain more than 5 Chinese characters.
  --location: string # User's location.
  --manager: string # The manager for the user. (format: email)
  --phone-country: string # **Note:** This field has been **deprecated** and will not be supported in the future. Use the **country** field of the **phone_numbers** object instead to select the country for the phone number. [Country ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) of the phone number. For example, if the phone number provided in the `phone_number` field is a Brazil based number, the value of the `phone_country` field should be `BR`.
  --phone-number: string # **Note:** This field has been **deprecated** and will not be supported in the future. Use the **phone_numbers** field instead to assign phone number(s) to a user. Phone number of the user. To update a phone number, you must also provide the `phone_country` field.
  --phone-numbers: record # shape: {code?: string, country?: string, number?: string}
  --pmi: int # Personal meeting ID: length must be 10.
  --timezone: string # The time zone ID for a user profile. For this parameter value please refer to the ID value in the [timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list.
  --type: int@type-completer-13 # User types:`1` - Basic.`2` - Licensed.`3` - On-prem.`99` - None (this can only be set with `ssoCreate`).
  --use-pmi: oneof<nothing, bool> # Use Personal Meeting ID for instant meetings. (default: false)
  --vanity-name: string # Personal meeting room name.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: login_type, var: login_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cms_user_id, var: cms_user_id}, {name: company, var: company}, {name: custom_attributes, var: custom_attributes}, {name: dept, var: dept}, {name: first_name, var: first_name}, {name: group_id, var: group_id}, {name: host_key, var: host_key}, {name: job_title, var: job_title}, {name: language, var: language}, {name: last_name, var: last_name}, {name: location, var: location}, {name: manager, var: manager}, {name: phone_country, var: phone_country}, {name: phone_number, var: phone_number}, {name: phone_numbers, var: phone_numbers}, {name: pmi, var: pmi}, {name: timezone, var: timezone}, {name: type, var: type}, {name: use_pmi, var: use_pmi}, {name: vanity_name, var: vanity_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, login_type: $login_type, cms_user_id: $cms_user_id, company: $company, custom_attributes: $custom_attributes, dept: $dept, first_name: $first_name, group_id: $group_id, host_key: $host_key, job_title: $job_title, language: $language, last_name: $last_name, location: $location, manager: $manager, phone_country: $phone_country, phone_number: $phone_number, phone_numbers: $phone_numbers, pmi: $pmi, timezone: $timezone, type: $type, use_pmi: $use_pmi, vanity_name: $vanity_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user assistants
#
# DELETE /users/{userId}/assistants
# operationId: userAssistantsDelete
export def "user-assistants-delete" [
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
    path: "/users/{userId}/assistants"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user assistants
#
# GET /users/{userId}/assistants
# Returns: record<assistants: table<email: string, id: string>>
# operationId: userAssistants
export def "user-assistants" [
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
    path: "/users/{userId}/assistants"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add assistants
#
# POST /users/{userId}/assistants
# Returns: record<add_at: string, ids: string>
# operationId: userAssistantCreate
export def "user-assistant-create" [
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
  --assistants: list # List of User's assistants. — item shape: {email?: string, id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/assistants"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assistants, var: assistants}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, assistants: $assistants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a user assistant
#
# DELETE /users/{userId}/assistants/{assistantId}
# operationId: userAssistantDelete
export def "user-assistant-delete" [
  user_id: string
  assistant_id: string
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
    path: "/users/{userId}/assistants/{assistantId}"
    path_params: [{name: userId, var: user_id}, {name: assistantId, var: assistant_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, assistant_id: $assistant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user's email
#
# PUT /users/{userId}/email
# operationId: userEmailUpdate
export def "user-email-update" [
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
  email: string # User’s email. The length should be less than 128 characters. (format: email)
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/email"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List meeting templates
#
# GET /users/{userId}/meeting_templates
# Returns: record<templates: table<id: string, name: string, type: int>, total_records: int>
# operationId: listMeetingTemplates
export def "list-meeting-templates" [
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
    path: "/users/{userId}/meeting_templates"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List meetings
#
# GET /users/{userId}/meetings
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, meetings: table<agenda: string, created_at: string, duration: int, host_id: string, id: int, join_url: string, pmi: string, start_time: string, timezone: string, topic: string, type: int, uuid: string>>
# operationId: meetings
export def "meetings" [
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
  --type: string@type-completer-14 # The meeting types: `scheduled` - This includes all valid past meetings (unexpired), live meetings and upcoming scheduled meetings. It is equivalent to the combined list of "Previous Meetings" and "Upcoming Meetings" displayed in the user's [Meetings page](https://zoom.us/meeting) on the Zoom Web Portal.`live` - All the ongoing meetings.`upcoming` - All upcoming meetings including live meetings. (default: live)
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --page-number: string # The page number of the current page in the returned records.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/meetings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: type, var: type}, {name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: page_number, var: page_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, type: $type, page_size: $page_size, next_page_token: $next_page_token, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a meeting
#
# POST /users/{userId}/meetings
# Returns: record<assistant_id: string, host_email: string, id: int, registration_url: string, agenda: string, created_at: string, duration: int, h323_password: string, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, pmi: int, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, alternative_hosts_email_notification: bool, approval_type: int, approved_or_denied_countries_or_regions: record<approved_list: list, denied_list: list, enable: bool, method: string>, audio: string, authentication_domains: string, authentication_exception: list<record>, authentication_name: string, authentication_option: string, auto_recording: string, breakout_room: record<enable: bool, rooms: list>, close_registration: bool, cn_meeting: bool, contact_email: string, contact_name: string, custom_keys: list<record>, encryption_type: string, enforce_login: bool, enforce_login_domains: string, global_dial_in_countries: list<string>, global_dial_in_numbers: list<record>, host_video: bool, in_meeting: bool, jbh_time: int, join_before_host: bool, language_interpretation: record<enable: bool, interpreters: list>, meeting_authentication: bool, mute_upon_entry: bool, participant_video: bool, registrants_confirmation_email: bool, registrants_email_notification: bool, registration_type: int, show_share_button: bool, use_pmi: bool, waiting_room: bool, watermark: bool>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string, visible: bool>, type: int>
# operationId: meetingCreate
export def "meeting-create" [
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
  --agenda: string # Meeting description.
  --duration: int # Meeting duration (minutes). Used for scheduled meetings only.
  --password: string # Passcode to join the meeting. By default, passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ *] and can have a maximum of 10 characters. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recurrence: record # Recurrence object. Use this object only for a meeting with type `8` i.e., a recurring meeting with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
  --schedule-for: string # If you would like to schedule this meeting for someone else in your account, provide the Zoom user id or email address of the user here.
  --settings: record # Meeting settings. — shape: {additional_data_center_regions?: list<string>, allow_multiple_devices?: bool, alternative_hosts?: string, alternative_hosts_email_notification?: bool, approval_type?: "0"|"1"|"2", approved_or_denied_countries_or_regions?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", breakout_room?: record, close_registration?: bool, cn_meeting?: bool, contact_email?: string, contact_name?: string, ... (16 more fields)}
  --start-time: string # Meeting start time. We support two formats for `start_time` - local time and GMT. To set time as GMT the format should be `yyyy-MM-dd`T`HH:mm:ssZ`. Example: "2020-03-31T12:02:00Z" To set time using a specific timezone, use `yyyy-MM-dd`T`HH:mm:ss` format and specify the timezone [ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) in the `timezone` field OR leave it blank and the timezone set on your Zoom account will be used. You can also set the time as UTC as the timezone field. The `start_time` should only be used for scheduled and / or recurring webinars with fixed time. (format: date-time)
  --template-id: string # Unique identifier of the **admin meeting template**. To create admin meeting templates, contact the Zoom support team. Use this field if you would like to [schedule the meeting from a admin meeting template](https://support.zoom.us/hc/en-us/articles/360036559151-Meeting-templates#h_86f06cff-0852-4998-81c5-c83663c176fb). You can retrieve the value of this field by calling the [List meeting templates](https://marketplace.zoom.us/docs/api-reference/zoom-api/meetings/listmeetingtemplates) API.
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [time zone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list for supported time zones and their formats.
  --topic: string # Meeting topic.
  --tracking-fields: list # Tracking fields — item shape: {field: string, value?: string}
  --type: int@type-completer-2 # Meeting Type:`1` - Instant meeting.`2` - Scheduled meeting.`3` - Recurring meeting with no fixed time.`8` - Recurring meeting with fixed time. (default: 2)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/meetings"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agenda, var: agenda}, {name: duration, var: duration}, {name: password, var: password}, {name: recurrence, var: recurrence}, {name: schedule_for, var: schedule_for}, {name: settings, var: settings}, {name: start_time, var: start_time}, {name: template_id, var: template_id}, {name: timezone, var: timezone}, {name: topic, var: topic}, {name: tracking_fields, var: tracking_fields}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201, 300]
    auth: bearer
  } {
    user_id: $user_id, agenda: $agenda, duration: $duration, password: $password, recurrence: $recurrence, schedule_for: $schedule_for, settings: $settings, start_time: $start_time, template_id: $template_id, timezone: $timezone, topic: $topic, tracking_fields: $tracking_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List a user's PAC accounts
#
# GET /users/{userId}/pac
# Returns: record<pac_accounts: table<conference_id: int, dedicated_dial_in_number: list, global_dial_in_numbers: list, listen_only_password: string, participant_password: string>>
# operationId: userPACs
export def "user-pa-cs" [
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
    path: "/users/{userId}/pac"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a user's password
#
# PUT /users/{userId}/password
# operationId: userPassword
export def "user-password" [
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
  password: string # User password. Should be less than 32 characters. **Note:** If the account owner or admin has enabled [enhanced password requirements](https://support.zoom.us/hc/en-us/articles/360034675592-Advanced-security-settings#h_fa9186e4-6818-4f7a-915c-2e25c19f0acd), the value provided in this field must meet those requirements. These requirements can be retrieved by calling the [Get Account Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) and referring to the `password_requirement` field present in the `security` object.
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/password"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user permissions
#
# GET /users/{userId}/permissions
# Returns: record<permissions: list<string>>
# operationId: userPermission
export def "user-permission" [
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
    path: "/users/{userId}/permissions"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Upload a user's profile picture
#
# POST /users/{userId}/picture
# operationId: userPicture
export def "user-picture" [
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
  pic_file: string # The file's path. (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{userId}/picture"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: pic_file, var: pic_file}], files: [pic_file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, pic_file: $pic_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user's presence status
#
# PUT /users/{userId}/presence_status
# operationId: updatePresenceStatus
export def "update-presence-status" [
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
  --duration: int # If you're updating the status to `Do_Not_Disturb`, specify a duration in minutes for which the status should remain as `Do_Not_Disturb`. The default value is 20 minutes and the maximum allowed value is 1440 minutes.
  --status: string@status-completer-5 # Presence status of the user. The value can be set to one of the following: * `Away` * `Do_Not_Disturb` * `Available` Users who are on Zoom Client with a version **lower than 5.3.0** can update the status from: * `Away` to `Do_Not_Disturb` * `Available` to `Do-Not_Disturb` Users who are on **Zoom Client 5.3.0** or higher can update the status from: * `Do_Not_Disturb` to `Away` * `Do_Not_Disturb` to `Available` * `Available` to `Away` * `Away` to `Available`
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/presence_status"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: duration, var: duration}, {name: status, var: status}]}
    accept: ["application/json", "application/xml"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, duration: $duration, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all recordings
#
# GET /users/{userId}/recordings
# Returns: record<from: string, to: string, next_page_token: string, page_count: int, page_size: int, total_records: int, meetings: table<account_id: string, duration: int, host_id: string, id: string, recording_count: string, start_time: string, topic: string, total_size: string, type: string, uuid: string, recording_files: list>>
# operationId: recordingsList
export def "recordings-list" [
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
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
  --mc: string # Query Metadata of Recording if an On-Premise Meeting Connector was used for the meeting. (default: false)
  --trash: oneof<nothing, bool> # Query trash. `true`: List recordings from trash. `false`: Do not list recordings from the trash. The default value is `false`. If you set it to `true`, you can use the `trash_type` property to indicate the type of Cloud recording that you need to retrieve. (default: false)
  --from: string # The start date in 'yyyy-mm-dd' UTC format for the date range for which you would like to retrieve recordings. The maximum range can be a month. If no value is provided for this field, the default will be current date. For example, if you make the API request on June 30, 2020, without providing the “from” and “to” parameters, by default the value of 'from' field will be “2020-06-30” and the value of the 'to' field will be “2020-07-01”. **Note**: The "trash" files cannot be filtered by date range and thus, the "from" and "to" fields should not be used for trash files. (format: date)
  --to: string # End date in 'yyyy-mm-dd' 'yyyy-mm-dd' UTC format. (format: date)
  --trash-type: string # The type of Cloud recording that you would like to retrieve from the trash. The value can be one of the following: `meeting_recordings`: List all meeting recordings from the trash. `recording_file`: List all individual recording files from the trash. (default: meeting_recordings)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/recordings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: next_page_token, var: next_page_token}, {name: mc, var: mc}, {name: trash, var: trash}, {name: from, var: from}, {name: to, var: to}, {name: trash_type, var: trash_type}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, next_page_token: $next_page_token, mc: $mc, trash: $trash, from: $from, to: $to, trash_type: $trash_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete user schedulers
#
# DELETE /users/{userId}/schedulers
# operationId: userSchedulersDelete
export def "user-schedulers-delete" [
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
    path: "/users/{userId}/schedulers"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user schedulers
#
# GET /users/{userId}/schedulers
# Returns: record<schedulers: table<email: string, id: string, pmi: int>>
# operationId: userSchedulers
export def "user-schedulers" [
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
    path: "/users/{userId}/schedulers"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a scheduler
#
# DELETE /users/{userId}/schedulers/{schedulerId}
# operationId: userSchedulerDelete
export def "user-scheduler-delete" [
  user_id: string
  scheduler_id: string
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
    path: "/users/{userId}/schedulers/{schedulerId}"
    path_params: [{name: userId, var: user_id}, {name: schedulerId, var: scheduler_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, scheduler_id: $scheduler_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user settings
#
# GET /users/{userId}/settings
# operationId: userSettings
export def "user-settings" [
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
  --login-type: string@login-type-completer # `0` - Facebook.`1` - Google.`99` - API.`100` - Zoom.`101` - SSO.
  --option: string@option-completer # `meeting_authentication`: Use this query parameter to view [meeting authentication configuration](https://support.zoom.us/hc/en-us/articles/360037117472-Authentication-Profiles-for-Meetings-and-Webinars) applied on the user's account.`recording_authentication`: Use this query parameter to view [recording authentication configuration](https://support.zoom.us/hc/en-us/articles/360037756671-Authentication-Profiles-for-Cloud-Recordings) applied on the user's account. `meeting_security`: Use this query parameter to view meeting security settings applied on the user's account. (allows empty value)
  --custom-query-fields: string # Provide the name of the field by which you would like to filter the response. For example, if you provide "host_video" as the value of this field, you will get a response similar to the following: { "schedule_meeting": { "host_video": false } } You can provide multiple values by separating them with commas(example: "host_video,participant_video”).
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{userId}/settings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: login_type, var: login_type}, {name: option, var: option}, {name: custom_query_fields, var: custom_query_fields}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, login_type: $login_type, option: $option, custom_query_fields: $custom_query_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user settings
#
# PATCH /users/{userId}/settings
# operationId: userSettingsUpdate
export def "user-settings-update" [
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
  --option: string@option-completer-3 # allows empty value
  --email-notification: record # shape: {alternative_host_reminder?: bool, cancel_meeting_reminder?: bool, jbh_reminder?: bool, schedule_for_reminder?: bool}
  --feature: record # shape: {large_meeting?: bool, large_meeting_capacity?: int, meeting_capacity?: int, webinar?: bool, webinar_capacity?: int, zoom_phone?: bool}
  --in-meeting: record # shape: {allow_live_streaming?: bool, annotation?: bool, attendee_on_hold?: bool, auto_saving_chat?: bool, breakout_room?: bool, chat?: bool, closed_caption?: bool, co_host?: bool, custom_data_center_regions?: bool, custom_live_streaming_service?: bool, custom_service_instructions?: string, data_center_regions?: "HK"|"AU"|"IN"|"TY"|"CN"|"US"|"CA"|"DE"|"NL"|"LA", e2e_encryption?: bool, entry_exit_chime?: "host"|"all"|"none", far_end_camera_control?: bool, feedback?: bool, file_transfer?: bool, ... (17 more fields)}
  --profile: record # shape: {recording_storage_location?: record}
  --recording: record # shape: {ask_host_to_confirm_disclaimer?: bool, ask_participants_to_consent_disclaimer?: bool, auto_delete_cmr?: bool, auto_delete_cmr_days?: int, auto_recording?: "local"|"cloud"|"none", cloud_recording?: bool, host_pause_stop_recording?: bool, ip_address_access_control?: record, local_recording?: bool, record_audio_file?: bool, record_gallery_view?: bool, record_speaker_view?: bool, recording_audio_transcript?: bool, recording_disclaimer?: bool, recording_password_requirement?: record, ... (2 more fields)}
  --schedule-meeting: record # shape: {audio_type?: "both"|"telephony"|"voip"|"thirdParty", default_password_for_scheduled_meetings?: string, embed_password_in_join_link?: bool, force_pmi_jbh_password?: bool, host_video?: bool, join_before_host?: bool, meeting_password_requirement?: record, participants_video?: bool, personal_meeting?: bool, pmi_password?: string, pstn_password_protected?: bool, require_password_for_instant_meetings?: bool, require_password_for_pmi_meetings?: "jbh_only"|"all"|"none", ... (4 more fields)}
  --telephony: record # shape: {audio_conference_info?: string, show_international_numbers_link?: bool, telephony_regions?: record, third_party_audio?: bool}
  --tsp: record # Account Settings: TSP. — shape: {call_out?: bool, call_out_countries?: list, show_international_numbers_link?: bool}
  --meeting-security: record # shape: {auto_security?: bool, embed_password_in_join_link?: bool, encryption_type?: "enhanced_encryption"|"e2ee", end_to_end_encrypted_meetings?: bool, meeting_password?: bool, meeting_password_requirement?: record, phone_password?: bool, pmi_password?: bool, require_password_for_scheduled_meeting?: bool, require_password_for_scheduled_webinar?: bool, waiting_room?: bool, waiting_room_settings?: record, webinar_password?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userId}/settings"
    path_params: [{name: userId, var: user_id}]
    query: [{name: option, var: option}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_notification, var: email_notification}, {name: feature, var: feature}, {name: in_meeting, var: in_meeting}, {name: profile, var: profile}, {name: recording, var: recording}, {name: schedule_meeting, var: schedule_meeting}, {name: telephony, var: telephony}, {name: tsp, var: tsp}, {name: meeting_security, var: meeting_security}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, option: $option, email_notification: $email_notification, feature: $feature, in_meeting: $in_meeting, profile: $profile, recording: $recording, schedule_meeting: $schedule_meeting, telephony: $telephony, tsp: $tsp, meeting_security: $meeting_security
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete virtual background files
#
# DELETE /users/{userId}/settings/virtual_backgrounds
# operationId: delUserVB
export def "del-user-vb" [
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
  --file-ids: string # Provide the id of the file that is to be deleted. To delete multiple files, provide comma separated values for this field.
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{userId}/settings/virtual_backgrounds"
    path_params: [{name: userId, var: user_id}]
    query: [{name: file_ids, var: file_ids}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, file_ids: $file_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload virtual background files
#
# POST /users/{userId}/settings/virtual_backgrounds
# Returns: record<id: string, is_default: bool, name: string, size: string, type: string>
# operationId: uploadVBuser
export def "upload-v-buser" [
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
  --file: string # Provide the file's path here.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/settings/virtual_backgrounds"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user status
#
# PUT /users/{userId}/status
# operationId: userStatus
export def "user-status" [
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
  action: string@action-completer-11 # The action types:`activate` - Activate a deactivated user.`deactivate` - Deactivate a user.
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{userId}/status"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    user_id: $user_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke a user's SSO token
#
# DELETE /users/{userId}/token
# operationId: userSSOTokenDelete
export def "user-sso-token-delete" [
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
    path: "/users/{userId}/token"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user token
#
# GET /users/{userId}/token
# Returns: record<token: string>
# operationId: userToken
export def "user-token" [
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
  --type: string@type-completer-15 # User token types:`token` - Used for starting meetings with the client SDK. This token expires in 14 days and a new token will be returned after the expiry.`zak` - Used for generating the start meeting URL. The token expiration time is two hours. For API users, the expiration time is 90 days.
  --ttl: int # Use this field in conjunction with the `type` field where the value of `type` field is `zak`. The value of this field denotes the expiry time of the `zak` token in seconds. For example, if you would like the zak token to be expired after one hour of the token generation, the value of this field should be `3600`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/token"
    path_params: [{name: userId, var: user_id}]
    query: [{name: type, var: type}, {name: ttl, var: ttl}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, type: $type, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List user's TSP accounts
#
# GET /users/{userId}/tsp
# Returns: record<tsp_accounts: table<conference_code: string, dial_in_numbers: list, id: int, leader_pin: string, tsp_bridge: string>>
# operationId: userTSPs
export def "user-ts-ps" [
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
    path: "/users/{userId}/tsp"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a user's TSP account
#
# POST /users/{userId}/tsp
# Returns: record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, leader_pin: string, tsp_bridge: string>
# operationId: userTSPCreate
export def "user-tsp-create" [
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
  conference_code: string # Conference code: numeric value, length is less than 16.
  --dial-in-numbers: list # List of dial in numbers. — item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
  leader_pin: string # Leader PIN: numeric value, length is less than 16.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/tsp"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conference_code, var: conference_code}, {name: dial_in_numbers, var: dial_in_numbers}, {name: leader_pin, var: leader_pin}, {name: tsp_bridge, var: tsp_bridge}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, conference_code: $conference_code, dial_in_numbers: $dial_in_numbers, leader_pin: $leader_pin, tsp_bridge: $tsp_bridge
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set global dial-in URL for a TSP user
#
# PATCH /users/{userId}/tsp/settings
# operationId: tspUrlUpdate
export def "tsp-url-update" [
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
  --audio-url: string # The global dial-in URL for a TSP enabled account. The URL must be valid with a max-length of 512 characters.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userId}/tsp/settings"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: audio_url, var: audio_url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, audio_url: $audio_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user's TSP account
#
# DELETE /users/{userId}/tsp/{tspId}
# operationId: userTSPDelete
export def "user-tsp-delete" [
  user_id: string
  tsp_id: string@tsp-id-completer
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
    path: "/users/{userId}/tsp/{tspId}"
    path_params: [{name: userId, var: user_id}, {name: tspId, var: tsp_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, tsp_id: $tsp_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's TSP account
#
# GET /users/{userId}/tsp/{tspId}
# Returns: record<conference_code: string, dial_in_numbers: table<code: string, country_label: string, number: string, type: string>, id: int, leader_pin: string, tsp_bridge: string>
# operationId: userTSP
export def "user-tsp" [
  user_id: string
  tsp_id: string@tsp-id-completer
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/users/{userId}/tsp/{tspId}"
    path_params: [{name: userId, var: user_id}, {name: tspId, var: tsp_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, tsp_id: $tsp_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a TSP account
#
# PATCH /users/{userId}/tsp/{tspId}
# operationId: userTSPUpdate
export def "user-tsp-update" [
  user_id: string
  tsp_id: string@tsp-id-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  conference_code: string # Conference code: numeric value, length is less than 16.
  --dial-in-numbers: list # List of dial in numbers. — item shape: {code?: string, country_label?: string, number?: string, type?: "toll"|"tollfree"|"media_link"}
  leader_pin: string # Leader PIN: numeric value, length is less than 16.
  --tsp-bridge: string@tsp-bridge-completer # Telephony bridge
]: any -> any {
  $in | http-request {
    method: patch
    path: "/users/{userId}/tsp/{tspId}"
    path_params: [{name: userId, var: user_id}, {name: tspId, var: tsp_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conference_code, var: conference_code}, {name: dial_in_numbers, var: dial_in_numbers}, {name: leader_pin, var: leader_pin}, {name: tsp_bridge, var: tsp_bridge}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, tsp_id: $tsp_id, conference_code: $conference_code, dial_in_numbers: $dial_in_numbers, leader_pin: $leader_pin, tsp_bridge: $tsp_bridge
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webinar templates
#
# GET /users/{userId}/webinar_templates
# Returns: record<templates: table<id: string, name: string>, total_records: int>
# operationId: listWebinarTemplates
export def "list-webinar-templates" [
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
    path: "/users/{userId}/webinar_templates"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List webinars
#
# GET /users/{userId}/webinars
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, webinars: table<agenda: string, created_at: string, duration: int, host_id: string, id: int, join_url: string, start_time: string, timezone: string, topic: string, type: string, uuid: string>>
# operationId: webinars
export def "webinars" [
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
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}/webinars"
    path_params: [{name: userId, var: user_id}]
    query: [{name: page_size, var: page_size}, {name: page_number, var: page_number}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, page_size: $page_size, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a webinar
#
# POST /users/{userId}/webinars
# Returns: record<host_email: string, host_id: string, id: int, registrants_confirmation_email: bool, template_id: string, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int>
# operationId: webinarCreate
export def "webinar-create" [
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
  --agenda: string # Webinar description.
  --duration: int # Webinar duration (minutes). Used for scheduled webinars only.
  --password: string # Webinar passcode. Passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ * !]. Max of 10 characters. If "Require a passcode when scheduling new meetings" setting has been **enabled** **and** [locked](https://support.zoom.us/hc/en-us/articles/115005269866-Using-Tiered-Settings#locked) for the user, the passcode field will be autogenerated for the Webinar in the response even if it is not provided in the API request. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API.
  --recurrence: record # Recurrence object. Use this object only for a webinar of type `9` i.e., a recurring webinar with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: string}
  --settings: record # Create Webinar settings. — shape: {allow_multiple_devices?: bool, alternative_hosts?: string, approval_type?: "0"|"1"|"2", attendees_and_panelists_reminder_email_notification?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", close_registration?: bool, contact_email?: string, contact_name?: string, email_language?: string, enforce_login?: bool, enforce_login_domains?: string, follow_up_absentees_email_notification?: record, ... (16 more fields)}
  --start-time: string # Webinar start time. We support two formats for `start_time` - local time and GMT. To set time as GMT the format should be `yyyy-MM-dd`T`HH:mm:ssZ`. To set time using a specific timezone, use `yyyy-MM-dd`T`HH:mm:ss` format and specify the timezone [ID](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) in the `timezone` field OR leave it blank and the timezone set on your Zoom account will be used. You can also set the time as UTC as the timezone field. The `start_time` should only be used for scheduled and / or recurring webinars with fixed time. (format: date-time)
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list for supported time zones and their formats.
  --topic: string # Webinar topic.
  --tracking-fields: list # Tracking fields — item shape: {field: string, value?: string}
  --type: int@type-completer-16 # Webinar Types:`5` - Webinar.`6` - Recurring webinar with no fixed time.`9` - Recurring webinar with a fixed time. (default: 5)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{userId}/webinars"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agenda, var: agenda}, {name: duration, var: duration}, {name: password, var: password}, {name: recurrence, var: recurrence}, {name: settings, var: settings}, {name: start_time, var: start_time}, {name: timezone, var: timezone}, {name: topic, var: topic}, {name: tracking_fields, var: tracking_fields}, {name: type, var: type}]}
    accept: ["application/json", "application/xml"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, agenda: $agenda, duration: $duration, password: $password, recurrence: $recurrence, settings: $settings, start_time: $start_time, timezone: $timezone, topic: $topic, tracking_fields: $tracking_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a webinar
#
# DELETE /webinars/{webinarId}
# operationId: webinarDelete
export def "webinar-delete" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  --cancel-webinar-reminder: string # `true`: Notify panelists and registrants about the webinar cancellation via email. `false`: Do not send any email notification to webinar registrants and panelists. The default value of this field is `false`.
]: nothing -> any {
  http-request {
    method: delete
    path: "/webinars/{webinarId}"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: cancel_webinar_reminder, var: cancel_webinar_reminder}]
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_id: $occurrence_id, cancel_webinar_reminder: $cancel_webinar_reminder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webinar
#
# GET /webinars/{webinarId}
# Returns: record<host_email: string, host_id: string, id: int, uuid: string, agenda: string, created_at: string, duration: int, join_url: string, occurrences: table<duration: int, occurrence_id: string, start_time: string, status: string>, password: string, recurrence: record<end_date_time: string, end_times: int, monthly_day: int, monthly_week: int, monthly_week_day: int, repeat_interval: int, type: int, weekly_days: string>, settings: record<allow_multiple_devices: bool, alternative_hosts: string, approval_type: int, attendees_and_panelists_reminder_email_notification: record<enable: bool, type: int>, audio: string, authentication_domains: string, authentication_name: string, authentication_option: string, auto_recording: string, close_registration: bool, contact_email: string, contact_name: string, email_language: string, enforce_login: bool, enforce_login_domains: string, follow_up_absentees_email_notification: record<enable: bool, type: int>, follow_up_attendees_email_notification: record<enable: bool, type: int>, global_dial_in_countries: list<string>, hd_video: bool, host_video: bool, meeting_authentication: bool, notify_registrants: bool, on_demand: bool, panelists_invitation_email_notification: bool, panelists_video: bool, post_webinar_survey: bool, practice_session: bool, question_and_answer: record<allow_anonymous_questions: bool, answer_questions: string, attendees_can_comment: bool, attendees_can_upvote: bool, enable: bool>, registrants_confirmation_email: bool, registrants_email_notification: bool, registrants_restrict_number: int, registration_type: int, show_share_button: bool, survey_url: string>, start_time: string, start_url: string, timezone: string, topic: string, tracking_fields: table<field: string, value: string>, type: int>
# operationId: webinar
export def "webinar" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # Unique Identifier that identifies an occurrence of a recurring webinar. [Recurring webinars](https://support.zoom.us/hc/en-us/articles/216354763-How-to-Schedule-A-Recurring-Webinar) can have a maximum of 50 occurrences. When you create a recurring Webinar using [Create a Webinar API](https://marketplace.zoom.us/docs/api-reference/zoom-api/webinars/webinarcreate), you can retrieve the Occurrence ID from the response of the API call.
  --show-previous-occurrences: oneof<nothing, bool> # Set the value of this field to `true` if you would like to view Webinar details of all previous occurrences of a recurring Webinar.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webinars/{webinarId}"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: show_previous_occurrences, var: show_previous_occurrences}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_id: $occurrence_id, show_previous_occurrences: $show_previous_occurrences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a webinar
#
# PATCH /webinars/{webinarId}
# operationId: webinarUpdate
export def "webinar-update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # Webinar occurrence id. Support change of agenda, start_time, duration, settings: {host_video, panelist_video, hd_video, watermark, auto_recording}
  --agenda: string # Webinar description.
  --duration: int # Webinar duration (minutes). Used for scheduled webinar only.
  --password: string # [Webinar passcode](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords). By default, passcode may only contain the following characters: [a-z A-Z 0-9 @ - _ * !] and can have a maximum of 10 characters. **Note:** If the account owner or the admin has configured [minimum passcode requirement settings](https://support.zoom.us/hc/en-us/articles/360033559832-Meeting-and-webinar-passwords#h_a427384b-e383-4f80-864d-794bf0a37604), the passcode value provided here must meet those requirements. If the requirements are enabled, you can view those requirements by calling either the [Get User Settings API](https://marketplace.zoom.us/docs/api-reference/zoom-api/users/usersettings) or the [Get Account Settings](https://marketplace.zoom.us/docs/api-reference/zoom-api/accounts/accountsettings) API. If "**Require a passcode when scheduling new meetings**" setting has been **enabled** **and** [locked](https://support.zoom.us/hc/en-us/articles/115005269866-Using-Tiered-Settings#locked) for the user, the passcode field will be autogenerated for the Webinar in the response even if it is not provided in the API request.
  --recurrence: record # Recurrence object. Use this object only for a meeting with type `8` i.e., a recurring meeting with fixed time. — shape: {end_date_time?: string, end_times?: int, monthly_day?: int, monthly_week?: "-1"|"1"|"2"|"3"|"4", monthly_week_day?: "1"|"2"|"3"|"4"|"5"|"6"|"7", repeat_interval?: int, type: "1"|"2"|"3", weekly_days?: "1"|"2"|"3"|"4"|"5"|"6"|"7"}
  --settings: record # Webinar settings. — shape: {allow_multiple_devices?: bool, alternative_hosts?: string, approval_type?: "0"|"1"|"2", attendees_and_panelists_reminder_email_notification?: record, audio?: "both"|"telephony"|"voip", authentication_domains?: string, authentication_name?: string, authentication_option?: string, auto_recording?: "local"|"cloud"|"none", close_registration?: bool, contact_email?: string, contact_name?: string, email_language?: string, enforce_login?: bool, enforce_login_domains?: string, ... (19 more fields)}
  --start-time: string # Webinar start time, in the format "yyyy-MM-dd'T'HH:mm:ss'Z'." Should be in GMT time. In the format "yyyy-MM-dd'T'HH:mm:ss." This should be in local time and the timezone should be specified. Only used for scheduled webinars and recurring webinars with a fixed time. (format: date-time)
  --timezone: string # Time zone to format start_time. For example, "America/Los_Angeles". For scheduled meetings only. Please reference our [time zone](#timezones) list for supported time zones and their formats.
  --topic: string # Webinar topic.
  --tracking-fields: list # Tracking fields — item shape: {field?: string, value?: string}
  --type: int@type-completer-16 # Webinar Types:`5` - webinar.`6` - Recurring webinar with no fixed time.`9` - Recurring webinar with a fixed time. (default: 5)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/webinars/{webinarId}"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agenda, var: agenda}, {name: duration, var: duration}, {name: password, var: password}, {name: recurrence, var: recurrence}, {name: settings, var: settings}, {name: start_time, var: start_time}, {name: timezone, var: timezone}, {name: topic, var: topic}, {name: tracking_fields, var: tracking_fields}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 204, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_id: $occurrence_id, agenda: $agenda, duration: $duration, password: $password, recurrence: $recurrence, settings: $settings, start_time: $start_time, timezone: $timezone, topic: $topic, tracking_fields: $tracking_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform batch registration
#
# POST /webinars/{webinarId}/batch_registrants
# Returns: record<registrants: table<email: string, join_url: string, registrant_id: string>>
# operationId: addBatchWebinarRegistrants
export def "add-batch-webinar-registrants" [
  webinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --auto-approve: oneof<nothing, bool> # If a meeting was scheduled with approval_type `1` (manual approval), but you would like to automatically approve the registrants that are added via this API, you can set the value of this field to `true`. You **cannot** use this field to change approval setting for a meeting that was originally scheduled with approval_type `0` (automatic approval).
  --registrants: list # item shape: {email: string, first_name: string, last_name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webinars/{webinarId}/batch_registrants"
    path_params: [{name: webinarId, var: webinar_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_approve, var: auto_approve}, {name: registrants, var: registrants}]}
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id, auto_approve: $auto_approve, registrants: $registrants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove panelists
#
# DELETE /webinars/{webinarId}/panelists
# operationId: webinarPanelistsDelete
export def "webinar-panelists-delete" [
  webinar_id: int
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
    path: "/webinars/{webinarId}/panelists"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List panelists
#
# GET /webinars/{webinarId}/panelists
# Returns: record<panelists: table<id: string, email: string, name: string, join_url: string>, total_records: int>
# operationId: webinarPanelists
export def "webinar-panelists" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/webinars/{webinarId}/panelists"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add panelists
#
# POST /webinars/{webinarId}/panelists
# Returns: record<id: string, updated_at: string>
# operationId: webinarPanelistCreate
export def "webinar-panelist-create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --panelists: list # List of panelist objects. — item shape: {email?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webinars/{webinarId}/panelists"
    path_params: [{name: webinarId, var: webinar_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: panelists, var: panelists}]}
    accept: ["application/json", "application/xml"]
    ok: [200, 201]
    auth: bearer
  } {
    webinar_id: $webinar_id, panelists: $panelists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Remove a panelist
#
# DELETE /webinars/{webinarId}/panelists/{panelistId}
# operationId: webinarPanelistDelete
export def "webinar-panelist-delete" [
  webinar_id: int
  panelist_id: int
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
    path: "/webinars/{webinarId}/panelists/{panelistId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: panelistId, var: panelist_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    webinar_id: $webinar_id, panelist_id: $panelist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a webinar's polls
#
# GET /webinars/{webinarId}/polls
# Returns: record<polls: table<id: string, status: string, questions: list, title: string>, total_records: int>
# operationId: webinarPolls
export def "webinar-polls" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/webinars/{webinarId}/polls"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a webinar's poll
#
# POST /webinars/{webinarId}/polls
# Returns: record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>
# operationId: webinarPollCreate
export def "webinar-poll-create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webinars/{webinarId}/polls"
    path_params: [{name: webinarId, var: webinar_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: questions, var: questions}, {name: title, var: title}]}
    accept: ["application/json", "application/xml"]
    ok: [201, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, questions: $questions, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a webinar poll
#
# DELETE /webinars/{webinarId}/polls/{pollId}
# operationId: webinarPollDelete
export def "webinar-poll-delete" [
  webinar_id: int
  poll_id: string
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
    path: "/webinars/{webinarId}/polls/{pollId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: pollId, var: poll_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webinar_id: $webinar_id, poll_id: $poll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webinar poll
#
# GET /webinars/{webinarId}/polls/{pollId}
# Returns: record<id: string, status: string, questions: table<answers: list, name: string, type: string>, title: string>
# operationId: webinarPollGet
export def "webinar-poll-get" [
  webinar_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/webinars/{webinarId}/polls/{pollId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: pollId, var: poll_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id, poll_id: $poll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a webinar poll
#
# PUT /webinars/{webinarId}/polls/{pollId}
# operationId: webinarPollUpdate
export def "webinar-poll-update" [
  webinar_id: int
  poll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --questions: list # Array of Polls — item shape: {answers?: list<string>, name?: string, type?: "single"|"multiple"}
  --title: string # Title for the poll.
]: any -> any {
  $in | http-request {
    method: put
    path: "/webinars/{webinarId}/polls/{pollId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: pollId, var: poll_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: questions, var: questions}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webinar_id: $webinar_id, poll_id: $poll_id, questions: $questions, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webinar registrants
#
# GET /webinars/{webinarId}/registrants
# Returns: record<next_page_token: string, page_count: int, page_number: int, page_size: int, total_records: int, registrants: table<id: string, address: string, city: string, comments: string, country: string, custom_questions: list, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>>
# operationId: webinarRegistrants
export def "webinar-registrants" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
  --status: string@status-completer # The registrant status:`pending` - Registrant's status is pending.`approved` - Registrant's status is approved.`denied` - Registrant's status is denied. (default: approved)
  --tracking-source-id: string # The tracking source ID for the registrants. Useful if you share the webinar registration page in multiple locations. See [Creating source tracking links for webinar registration](https://support.zoom.us/hc/en-us/articles/360000315683-Creating-source-tracking-links-for-webinar-registration) for details.
  --page-size: int # The number of records returned within a single API call. (default: 30)
  --page-number: int # **Deprecated** - This field has been deprecated and we will stop supporting it completely in a future release. Please use "next_page_token" for pagination instead of this field. The page number of the current page in the returned records. (default: 1)
  --next-page-token: string # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webinars/{webinarId}/registrants"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_id, var: occurrence_id}, {name: status, var: status}, {name: tracking_source_id, var: tracking_source_id}, {name: page_size, var: page_size}, {name: page_number, var: page_number}, {name: next_page_token, var: next_page_token}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_id: $occurrence_id, status: $status, tracking_source_id: $tracking_source_id, page_size: $page_size, page_number: $page_number, next_page_token: $next_page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a webinar registrant
#
# POST /webinars/{webinarId}/registrants
# Returns: record<id: string, join_url: string, registrant_id: string, start_time: string, topic: string>
# operationId: webinarRegistrantCreate
export def "webinar-registrant-create" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-ids: string # Occurrence ID. Get this value from the webinar get API. Multiple values separated by a comma.
  --address: string # Registrant's address.
  --city: string # Registrant's city.
  --comments: string # A field that allows registrants to provide any questions or comments that they might have.
  --country: string # Registrant's country. The value of this field must be in two-letter abbreviated form and must match the ID field provided in the [Countries](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#countries) table.
  --custom-questions: list # Custom questions. — item shape: {title?: string, value?: string}
  email: string # A valid email address of the registrant.
  first_name: string # Registrant's first name.
  --industry: string # Registrant's Industry.
  --job-title: string # Registrant's job title.
  --last-name: string # Registrant's last name.
  --no-of-employees: string # Number of Employees:`1-20``21-50``51-100``101-500``500-1,000``1,001-5,000``5,001-10,000``More than 10,000`
  --org: string # Registrant's Organization.
  --phone: string # Registrant's Phone number.
  --purchasing-time-frame: string # This field can be included to gauge interest of webinar attendees towards buying your product or service. Purchasing Time Frame:`Within a month``1-3 months``4-6 months``More than 6 months``No timeframe`
  --role-in-purchase-process: string # Role in Purchase Process:`Decision Maker``Evaluator/Recommender``Influencer``Not involved`
  --state: string # Registrant's State/Province.
  --zip: string # Registrant's Zip/Postal Code.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webinars/{webinarId}/registrants"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_ids, var: occurrence_ids}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: city, var: city}, {name: comments, var: comments}, {name: country, var: country}, {name: custom_questions, var: custom_questions}, {name: email, var: email}, {name: first_name, var: first_name}, {name: industry, var: industry}, {name: job_title, var: job_title}, {name: last_name, var: last_name}, {name: no_of_employees, var: no_of_employees}, {name: org, var: org}, {name: phone, var: phone}, {name: purchasing_time_frame, var: purchasing_time_frame}, {name: role_in_purchase_process, var: role_in_purchase_process}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json", "application/xml"]
    ok: [201, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_ids: $occurrence_ids, address: $address, city: $city, comments: $comments, country: $country, custom_questions: $custom_questions, email: $email, first_name: $first_name, industry: $industry, job_title: $job_title, last_name: $last_name, no_of_employees: $no_of_employees, org: $org, phone: $phone, purchasing_time_frame: $purchasing_time_frame, role_in_purchase_process: $role_in_purchase_process, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List registration questions
#
# GET /webinars/{webinarId}/registrants/questions
# Returns: record<custom_questions: table<answers: list, required: bool, title: string, type: string>, questions: table<field_name: string, required: bool>>
# operationId: webinarRegistrantsQuestionsGet
export def "webinar-registrants-questions-get" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/webinars/{webinarId}/registrants/questions"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update registration questions
#
# PATCH /webinars/{webinarId}/registrants/questions
# operationId: webinarRegistrantQuestionUpdate
export def "webinar-registrant-question-update" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-questions: list # Array of Registrant Custom Questions. — item shape: {answers?: list<string>, required?: bool, title?: string, type?: "short"|"single_radio"|"single_dropdown"|"multiple"}
  --questions: list # Array of registration fields whose values should be provided by registrants during registration. — item shape: {field_name?: "last_name"|"address"|"city"|"country"|"zip"|"state"|"phone"|"industry"|"org"|"job_title"|"purchasing_time_frame"|"role_in_purchase_process"|"no_of_employees"|"comments", required?: bool}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/webinars/{webinarId}/registrants/questions"
    path_params: [{name: webinarId, var: webinar_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_questions, var: custom_questions}, {name: questions, var: questions}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webinar_id: $webinar_id, custom_questions: $custom_questions, questions: $questions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update registrant's status
#
# PUT /webinars/{webinarId}/registrants/status
# operationId: webinarRegistrantStatus
export def "webinar-registrant-status" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The meeting occurrence ID.
  action: string@action-completer-6 # Used to approve a registrant, deny a registrant, or cancel a previously approved registrant.
  --registrants: list # List of registrants. — item shape: {email?: string, id?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/webinars/{webinarId}/registrants/status"
    path_params: [{name: webinarId, var: webinar_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: registrants, var: registrants}]}
    accept: ["application/json"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, occurrence_id: $occurrence_id, action: $action, registrants: $registrants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webinar registrant
#
# DELETE /webinars/{webinarId}/registrants/{registrantId}
# operationId: deleteWebinarRegistrant
export def "delete-webinar-registrant" [
  webinar_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurrence-id: string # The webinar occurence ID.
]: nothing -> any {
  http-request {
    method: delete
    path: "/webinars/{webinarId}/registrants/{registrantId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: registrantId, var: registrant_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webinar_id: $webinar_id, registrant_id: $registrant_id, occurrence_id: $occurrence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webinar registrant
#
# GET /webinars/{webinarId}/registrants/{registrantId}
# Returns: record<id: string, address: string, city: string, comments: string, country: string, custom_questions: table<title: string, value: string>, email: string, first_name: string, industry: string, job_title: string, last_name: string, no_of_employees: string, org: string, phone: string, purchasing_time_frame: string, role_in_purchase_process: string, state: string, zip: string, create_time: string, join_url: string, status: string>
# operationId: webinarRegistrantGet
export def "webinar-registrant-get" [
  webinar_id: int
  registrant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occurrence-id: string # The meeting occurrence ID.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webinars/{webinarId}/registrants/{registrantId}"
    path_params: [{name: webinarId, var: webinar_id}, {name: registrantId, var: registrant_id}]
    query: [{name: occurrence_id, var: occurrence_id}]
    accept: ["application/json", "application/xml"]
    ok: [200, 300]
    auth: bearer
  } {
    webinar_id: $webinar_id, registrant_id: $registrant_id, occurrence_id: $occurrence_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update webinar status
#
# PUT /webinars/{webinarId}/status
# operationId: webinarStatus
export def "webinar-status" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12
]: any -> any {
  $in | http-request {
    method: put
    path: "/webinars/{webinarId}/status"
    path_params: [{name: webinarId, var: webinar_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    webinar_id: $webinar_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get webinar tracking sources
#
# GET /webinars/{webinarId}/tracking_sources
# Returns: record<total_records: int, tracking_sources: table<id: string, registration_count: int, source_name: string, tracking_url: string, visitor_count: int>>
# operationId: getTrackingSources
export def "get-tracking-sources" [
  webinar_id: int
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/webinars/{webinarId}/tracking_sources"
    path_params: [{name: webinarId, var: webinar_id}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    webinar_id: $webinar_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
